package Jabbot::FrontEnd::IRC;
use strict;
use warnings;
use Jabbot::FrontEnd -base;
use POE qw(Session
           Component::IRC
           Component::IKC::Server
           Component::IKC::Specifier);
use Encode qw(encode decode);

my $config;
my $self;

sub process {
    $self= shift;
    $config = $self->config;
    POE::Component::IKC::Server->spawn(
        port => $self->config->{irc_frontend_port},
        name => $self->config->{nick}
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
                autoping         => \&bot_do_autoping,
                message          => \&jabbotmsg,
                _default         => $ENV{DEBUG} ? \&bot_default : sub {},
            }
           );
    }

    $poe_kernel->run();
}

sub jabbotmsg {
    my ($kernel,$heap,$msg) = @_[KERNEL,HEAP,ARG0];
   my $network = $heap->{network};
    eval {
        my $text = $msg->{text};
	Encode::from_to($text,'utf8','big5');
        my $channel = $msg->{channel};
        my @channels;
        if($channel eq '-ALL') {
            @channels = @{$self->config->{irc_channels}};
        } elsif(ref($channel) eq 'ARRAY') {
            @channels = @$channel;
        } else {
            @channels = [$channel];
        }
        $kernel->post("${network}" => privmsg => "#$_", $text )
            for(@channels);
        say "[#$channel] $msg->{text} on " . localtime(time);
    };
    say "update error: $@" if $@;
}

sub bot_default {
    my ($event,$args) = @_[ ARG0 .. $#_ ];
    say "unhandled $event";
    say "  - $_" foreach @$args;
    return 0;
};

sub bot_start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    my $network = $heap->{network};
    say "Starting irc session, Connecting to $network";
    $kernel->call( IKC => publish => "${network}" => ['message'] );
    $kernel->post( $network => register => 'all' );
    $kernel->post( $network => connect => {
        Nick =>   $config->{nick},
        Server => $config->{"irc_${network}_server"}
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
    $kernel->delay(autoping=>undef);
    $kernel->delay(connect=>60);
}

sub bot_public {
    my ($kernel,$heap,$who,$where,$msg) = @_[KERNEL,HEAP,ARG0..$#_];
    my $network = $heap->{network};
    my $nick = ( split /!/, $who )[0];
    my $channel = $where->[0];
    my $pubmsg  = decode('big5',$msg);
    my $to = sub {
       return '' if($_[0] =~ /^http/i);
       if($_[0] =~ s/^([\d\w\|]+)\s*[:,]\s*//) { return $1; }
       return '';
    }->($pubmsg);
    my $reply = $self->hub->process($pubmsg);
    my $reply_text = $reply->text;
    if(length($reply_text) &&
           ($to eq $self->config->{nick} || $reply->must_say)) {
        $reply_text = encode('big5',"$nick: $reply_text");
        $kernel->post($network => privmsg => $channel, $reply_text);
    }
}

1;
