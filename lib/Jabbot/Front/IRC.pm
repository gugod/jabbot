package Jabbot::Front::IRC;
use 5.012;
use utf8;
use JSON qw(decode_json encode_json);
use Encode qw(encode_utf8);
use Jabbot;

use AnyEvent;
use AnyEvent::MP;
use AnyEvent::MP::Global;
use AnyEvent::IRC::Client;

sub init_irc_client {
    my ($network) = @_;

    my @connection_args = (
        $network->{server},
        $network->{port} || 6667,
        { nick => $network->{nick} }
    );

    my $client = AnyEvent::IRC::Client->new;
    $client->reg_cb(
        registered => sub {
            my ($client) = @_;
            say STDERR "[IRC] Connected to $network->{server}.";

            for (@{$network->{channels}}) {
                my ($channel, $key) = ref($_) ? @$_ : ($_);
                $channel = "#${channel}" unless index($channel, "#") == 0;
                $client->send_srv('JOIN', $channel, $key);
            }

            $client->enable_ping(
                300,
                sub {
                    my ($conn) = @_;
                    say STDERR "Connection Timeout\n";
                    $conn->disconnect("Connection Timeout.");
                    $client->connect(@connection_args);
                }
            );
        },

        join => sub {
            my ($client, $nick, $channel, $is_myself) = @_;
            if ($is_myself) {
                say STDERR "[IRC] Joined $channel";
            }
        },

        publicmsg => sub {
            my ($client, $channel, $ircmsg) = @_;
            my $text = Encode::decode("utf8", $ircmsg->{params}[1]);
            my $to_me = $text =~ s/^jabbot_*:\s+//;
            my $from_nick = AnyEvent::IRC::Util::prefix_nick($ircmsg->{prefix}) || "";

            return if $from_nick =~ /jabbot_*/;

            my $ports = grp_get "jabbot-core" or return;

            for (@$ports) {
                snd $_, action => {
                    name => 'answer',
                    node => "jabbot-irc",
                    args => {
                        network  => $network->{name},
                        channel  => $channel,
                        from     => $from_nick,
                        to_me    => $to_me,
                        question => $text
                    }
                };
            }
        }
    );

    $client->connect(@connection_args);
    return $client;
}

sub run {
    configure profile => "jabbot-irc";

    my $IRC_CLIENTS = {};
    my $networks = Jabbot->config->{irc}{networks};
    for (keys %$networks) {
        $networks->{$_}{name} = $_;
        $networks->{$_}{nick} ||= (Jabbot->config->{nick} || "jabbot_$$");
        $IRC_CLIENTS->{$_} = init_irc_client($networks->{$_})
    }

    my @irc_privmsg_q;
    my $irc_privmsg_t;

    my $irc_send_privmsg  = sub {
        return unless $IRC_CLIENTS->{$_[0]};

        push @irc_privmsg_q, [@_];

        $irc_privmsg_t ||= AE::timer 1, 1, sub {
            my ($network, $channel, $body, $command) = @{shift @irc_privmsg_q};
            $command ||= 'PRIVMSG';
            $command = uc $command;

            my $client  = $IRC_CLIENTS->{$network};
            unless ($client->channel_list($channel)) {
                $client->send_srv("JOIN", $channel);
            }

            $client->send_chan($channel, $command, $channel, $body);

            undef $irc_privmsg_t unless @irc_privmsg_q;
        };
    };

    my $port = rcv(
        port,

        post => sub {
            my ($data, $reply_port) = @_;
            $irc_send_privmsg->($data->{network}, $data->{channel}, encode_utf8($data->{body}) , $data->{command});
        },

        reply => sub {
            my ($data) = @_;
            return unless $data->{to_me} || $data->{answer}{confidence} == 1;

            my $body = encode_utf8(
                ($data->{to_me} ? ($data->{from} . ": ") : "") . $data->{answer}{content}
            );

            $irc_send_privmsg->($data->{network}, $data->{channel}, $body);
        }
    );

    my $guard = grp_reg "jabbot-irc", $port;

    AnyEvent->condvar->recv;
}

sub cat {
    my ($class, $network, $channel, $body) = @_;

    configure;

    my $cv = AnyEvent->condvar;

    my $w = AnyEvent->timer(
        after => 1,
        cb => sub {
            my $irc = grp_get "jabbot-irc";
            if ($irc) {
                snd $_, post => {
                    network => $network,
                    channel => $channel,
                    body    => $body
                } for @$irc;
            }
            else {
                warn "No port found for jabbot-irc. Huh?";
            }

            $cv->send;
        }
    );

    $cv->recv;
}

1;

=head1 SYNOPSIS

Launch the irc clients

    perl -MJabbot::Front::IRC -e "Jabbot::Front::IRC->run";

Post to the givent channel (auto-joined if not alreay joined):

    perl -MJabbot::Front::IRC -e 'Jabbot::Front::IRC->cat(@ARGV)' freenode '#jabbot' "Ni Hao";

=cut
