package Jabbot::FrontEnd::IRC;
use strict;
use warnings;
use Jabbot::FrontEnd -base;
use POE qw(Session
           Component::IRC
           Component::IKC::Server
           Component::IKC::Specifier);
use Encode qw(encode decode);

sub msg { print " * @_\n" }
sub err { print " * @_\n" }

my $config;
my $self;

sub process {
    $self= shift;
    $config = $self->config;
    POE::Component::IKC::Server->spawn(
        port => $self->config->{irc_daemon_port},
        name => $self->config->{nick}
       );

    POE::Component::IRC->new('bot')
            or die "Couldn't create IRC POE session: $!";

    POE::Session->create(
        inline_states => {
            _start           => \&bot_start,
            _stop            => \&bot_stop,
            irc_001          => \&bot_connected,
            irc_372          => \&bot_motd,
            irc_disconnected => \&bot_reconnect,
            irc_error        => \&bot_reconnect,
            irc_socketerr    => \&bot_reconnect,
            irc_public       => \&bot_public,
            autoping         => \&bot_do_autoping,
            update           => \&jabbotmsg,
            _default         => $ENV{DEBUG} ? \&bot_default : sub {},
        }
       );
    POE::Kernel->run();
}

sub jabbotmsg {
    my ($kernel,$heap,$msg) = @_[KERNEL,HEAP,ARG0];
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
        $kernel->post(bot => privmsg => "#$_", $text )
            for(@channels);
        msg "[#$channel] $msg->{text} on " . localtime(time);
    };
    err "update error: $@" if $@;
}

sub bot_default {
    my ($event,$args) = @_[ ARG0 .. $#_ ];
    err "unhandled $event";
    err "  - $_" foreach @$args;
    return 0;
};

sub bot_start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    msg "starting irc session";
    $kernel->alias_set('frontend_irc');
    $kernel->call( IKC => publish => frontend_irc => ['update'] );
    $kernel->post( bot => register => 'all' );
    $kernel->post( bot => connect => {
        Nick=>$config->{nick},
        Server=>$config->{irc_server},
    });
}

sub bot_stop {
    msg "stopping bot";
}

sub bot_connected {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    foreach (@{$config->{irc_channels}}) {
        msg "joining channel #$_";
        $kernel->post(bot=>join=>"#$_")
    }
}

sub bot_motd {
    msg '[motd] ' . $_[ARG1];
}

sub bot_do_autoping {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    $kernel->post(bot=>userhost=>$config->{notify_irc_nickname})
      unless $heap->{seen_traffic};
    $heap->{seen_traffic} = 0;
    $kernel->delay(autoping=>300);
}

sub bot_reconnect {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    err "reconnect: ".$_[ARG0];
    $kernel->delay(autoping=>undef);
    $kernel->delay(connect=>60);
}

sub bot_public {
    my ($kernel,$heap,$who,$where,$msg) = @_[KERNEL,HEAP,ARG0..$#_];
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
        $kernel->post(bot => privmsg => $channel, $reply_text);
    }
}


1;
