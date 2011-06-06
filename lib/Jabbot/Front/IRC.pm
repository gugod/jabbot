package Jabbot::Front::IRC;
use 5.012;
use common::sense;
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
            my $text = $ircmsg->{params}[1];
            my $to_me = $text =~ s/^jabbot_*:\s+//;
            my $from_nick = AnyEvent::IRC::Util::prefix_nick($ircmsg->{prefix}) || "";

            my $ports = grp_get "jabbot_core" or return;

            for (@$ports) {
                snd $_, action => {
                    name => 'answers',
                    args => {
                        question => $text,
                        network  => $network->{name},
                        channel  => $channel,
                        from     => $from_nick,
                        to_me    => $to_me
                    }
                };
            }
        }
    );

    $client->connect(@connection_args);
    return $client;
}

sub run {
    configure;

    my $IRC_CLIENTS = {};
    my $networks = Jabbot->config->{irc}{networks};
    for (keys %$networks) {
        $networks->{$_}{name} = $_;
        $networks->{$_}{nick} ||= (Jabbot->config->{nick} || "jabbot_$$");
        $IRC_CLIENTS->{$_} = init_irc_client($networks->{$_})
    }

    my $port = rcv(
        port,

        post => sub {
            my ($data, $reply_port) = @_;

            if (my $client = $IRC_CLIENTS->{$data->{network}}) {
                my $channel = $data->{channel};
                my $body    = $data->{body};

                unless ($client->channel_list($channel)) {
                    $client->send_srv("JOIN", $channel);
                }
                $client->send_chan($channel, "PRIVMSG", $channel, $body);
            }
        },

        reply => sub {
            my ($data, $reply_port) = @_;
            return unless $data->{to_me};

            my $client  = $IRC_CLIENTS->{$data->{network}} or return;
            my $channel = $data->{channel};
            my $body    = $data->{from} . ": " . $data->{answers}[0]{content};

            unless ($client->channel_list($channel)) {
                $client->send_srv("JOIN", $channel);
            }

            $client->send_chan($channel, "PRIVMSG", $channel, encode_utf8($body));
        }
    );

    my $guard = grp_reg "jabbot_irc", $port;

    AnyEvent->condvar->recv;
}

sub cat {
    configure;

    my ($class, $network, $channel, $body) = @_;

    my $cv = AnyEvent->condvar;

    my $w = AnyEvent->timer(
        after => 1,
        cb => sub {
            my $irc = grp_get "jabbot_irc" or die "Unable to send messages to irc clients.\n";

            snd $_, post => {
                network => $network,
                channel => $channel,
                body    => $body
            } for @$irc;

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
