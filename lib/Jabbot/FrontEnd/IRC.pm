package Jabbot::FrontEnd::IRC;
use strict;
use warnings;
use Jabbot::FrontEnd -base;
use POE qw(Session
           Component::IRC
           Component::IRC::Plugin::Connector
           Component::IKC::Server
           Component::IKC::Specifier);

use Encode qw(encode decode from_to);

my $config;
my $self;

sub process {
    $self= shift;
    $config = $self->hub->config->{irc};

    POE::Component::IKC::Server->spawn(
        port => $config->{frontend_port},
        name => $self->hub->config->{nick}
    );

    for my $network (@{$config->{networks}}) {
        # POE::Component::IRC->new($network)

        my $irc = POE::Component::IRC->spawn(
            alias => "irc_frontend_${network}",
            Nick   => $self->hub->config->{nick},
            Server => $config->{$network}{server},
            Port   => $config->{$network}{port},
       ) or die "Couldn't create IRC POE session: $!";

        POE::Session->create(
            heap => {
                irc => $irc,
                network => $network,
            },
            inline_states => {
                _start           => \&bot_start,
                _stop            => sub { say "stopping bot" },
                irc_001          => \&bot_connected,
                irc_disconnected => \&bot_reconnect,
                irc_error        => \&bot_reconnect,
                irc_socketerr    => \&bot_reconnect,
                irc_public       => \&bot_public,
                irc_invite       => \&bot_invited,
                irc_msg          => \&bot_msg,
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

sub bot_invited {
    my ($kernel,$channel, $heap) = @_[KERNEL,ARG1, HEAP];
    my $network = $heap->{network};

    say "Bot invited to $network $channel";
    $kernel->post($network => join => $channel);
}

sub bot_start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    my $irc = $heap->{irc};
    my $alias = $irc->session_alias();
    my ($network) = $alias =~ /irc_frontend_(.+)/;
    say "Starting irc session, Connecting to $network";
    $kernel->call( IKC => publish => $alias => ['message'] );
    $irc->yield(register => 'all');
    $irc->yield(connect => {});
}

sub bot_connected {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    my $irc = $heap->{irc};
    my $alias = $irc->session_alias();
    my ($network) = $alias =~ /irc_frontend_(.+)/;

    say "Connected to $network";
    foreach(@{ $config->{$network}{channels} }) {
        my ($channel, $key) = split;
        say "Joining channel #channel";
        $irc->yield(join => "#${channel}", $key);
    }
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

    say "[$network/$who encoding=\"$encoding\"] $pubmsg";
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
    my $irc = $heap->{irc};
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

    if ($reply_text &&
        (($reply->must_say) ||
         ($to eq $self->hub->config->nick))
    ) {
        $reply_text = encode($encoding,"$nick: $reply_text");
        $irc->yield(privmsg => $channel, $reply_text);
    }
}

1;
