package Jabbot::FrontEnd::IRC;
use strict;
use warnings;
use Jabbot::FrontEnd -base;
use POE qw(Session
           Component::IRC
           Component::IKC::Server
           Component::IKC::Specifier);
use Encode qw(encode decode from_to);
use YAML;

my $config;
my $self;

sub process {
    $self= shift;
    $config = $self->hub->config;
    POE::Component::IKC::Server->spawn(
        port => $config->{irc_frontend_port},
        name => $config->{nick}
       );

    for my $network (@{$config->{irc_networks}}) {
        POE::Component::IRC->new($network)
                or die "Couldn't create IRC POE session: $!";
        POE::Session->create(
            heap => { network => $network },
            inline_states => {
                _start           => \&bot_start,
                _stop            => sub { say "stopping bot" },
                irc_001          => \&bot_connected,
                irc_disconnected => \&bot_reconnect,
                irc_error        => \&bot_reconnect,
                irc_socketerr    => \&bot_reconnect,
                irc_public       => \&bot_public,
                irc_msg          => \&bot_msg,
                irc_ping         => \&bot_ping,
                autoping         => \&bot_do_autoping,
		message          => \&jabbotmsg,
		_default         => \&bot_default,
		}
	);
    }

    $poe_kernel->run();
}

sub jabbotmsg {
    my ($kernel,$heap,$msg) = @_[KERNEL,HEAP,ARG0];
    my ($network,$channel) = @$msg{qw(network channel)};

# Notice:
# IKC-ClientLite has to use FreezeThaw as serializer instead of Storable.
# So that the scalar we get here are just bytes. Without utf8 flag turned on.
# Otherwise it turns encoding strings all mess!

# The $msg->{text} has utf8 flag off, but it's a valid utf8 sequence
    my $text = decode('utf8',$msg->{text});
    my $utf8_text = encode('utf8',$text);

    my $encoding = $self->hub->config->{"channel_encoding_${network}_${channel}"} || $self->hub->config->default_encoding || 'utf8';

    my $channel_text = encode($encoding,$text);

    $kernel->post($network, privmsg => "#$channel", $channel_text );
    say "[${network}/#$channel] on $utf8_text " . localtime(time);
    return 0;
}

sub bot_default {
    my ($state, $event, $args, $heap) = @_[STATE, ARG0, ARG1, HEAP];
    $args ||= [ ];
    say "default $state = $event (@$args)";
    $heap->{seen_traffic} = 1;
};

sub bot_start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    my $network = $heap->{network};
    say "Starting irc session, Connecting to $network";
    $kernel->alias_set("irc_frontend_${network}");
    $kernel->call( IKC => publish => "irc_frontend_${network}" => ['message'] );
    $kernel->post( $network => register => 'all' );
    $kernel->delay( autoping => 300 );

    $kernel->post( $network => connect => {
        Nick   => $config->{nick},
        Server => $config->{"irc_${network}_server"},
        Port   => $config->{"irc_${network}_port"},
    });
}

sub bot_connected {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    my $network = $heap->{network};
    say "Connected to $network";
    foreach (map {
        s/${network}://; $_
    } grep { /^${network}:/ } @{$config->{"irc_channels"}}) {
        say "Joining channel #$_";
        $kernel->post($network=>join=>"#$_");
    }
}

sub bot_do_autoping {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    my $network = $heap->{network};
    $kernel->post($network=>userhost=>$config->{notify_irc_nickname})
        unless $heap->{seen_traffic};
    $heap->{seen_traffic} = 0;
    $kernel->delay(autoping=>300);
}

sub bot_reconnect {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    say "reconnect: ".$_[ARG0];
    $kernel->delay(autoping=>300);
    $kernel->delay(connect=>60);
}

sub bot_msg {
    my ($kernel,$heap,$who,$where,$msg) = @_[KERNEL,HEAP,ARG0..$#_];
    my $network = $heap->{network};
    my $encoding = "utf8";
    my $pubmsg  = decode($encoding,$msg);
    my $nick = ( split /!/, $who )[0];

    say "[$network/$who encoding=\"$encoding\"] ". encode('utf8',$pubmsg);
    my $reply = $self->hub->process(
        $self->hub->message->new(
            text => $pubmsg,
            from => $nick,
            channel => '',
            to => $self->hub->config->nick,
           ));

    my $reply_text = $reply->text;
    if(length($reply_text)) {
        $reply_text = encode($encoding,$reply_text);
        $kernel->post($network => privmsg => $nick, $reply_text);
    }
}

sub bot_public {
    my ($kernel,$heap,$who,$where,$msg) = @_[KERNEL,HEAP,ARG0..$#_];
    my $network = $heap->{network};
    $heap->{seen_traffic} = 1;

    my $nick = ( split /!/, $who )[0];
    my $channel = lc($where->[0]);
    $channel =~ s{^\#}{};
    my $encoding = $self->hub->config->{"channel_encoding_${network}_${channel}"} || $self->hub->config->default_encoding || 'utf8';
    $channel = '#'.$channel;
    my $pubmsg  = decode($encoding,$msg);
    say "[$network/$channel encoding=\"$encoding\"] ". encode('utf8',$pubmsg);
    my $to = sub {
       return '' if($_[0] =~ /^\s*http/i);
       if($_[0] =~ s/^([\d\w\|]+)\s*[:,]\s*//) { return $1; }
       return '';
    }->($pubmsg);
    my $reply = $self->hub->process(
        $self->hub->message->new(
            text => $pubmsg,
            from => $nick,
            channel => $channel,
            to => $to
           ));
    my $reply_text = $reply->text;
    if(length($reply_text) &&
           ($to eq $self->hub->config->nick || $reply->must_say)) {
        $reply_text = encode($encoding,"$nick: $reply_text");
        $kernel->post($network => privmsg => $channel, $reply_text);
    }
}

sub bot_ping {
    my ($kernel,$heap,$who,$where,$msg) = @_[KERNEL,HEAP,ARG0..$#_];
    my $network = $heap->{network};
    $heap->{seen_traffic} = 1;
}

1;
