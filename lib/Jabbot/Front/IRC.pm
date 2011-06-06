package Jabbot::Front::IRC;
use 5.012;
use common::sense;
use JSON qw(decode_json encode_json to_json);
use Encode ();
use Plack::Request;
use Jabbot;
use Jabbot::RemoteCore;
use AnyEvent;
use AnyEvent::MP;
use AnyEvent::MP::Global;
use AnyEvent::IRC::Client;

configure;

my $IRC_CLIENTS = {};
my $networks = Jabbot->config->{irc}{networks};
for (keys %$networks) {
    $networks->{$_}{name} = $_;
    $networks->{$_}{nick} ||= (Jabbot->config->{nick} || "jabbot_$$");
    $IRC_CLIENTS->{$_} = init_irc_client($networks->{$_})
}

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
                say STDERR "[IRC] Joind $channel";
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

            # my $rc = Jabbot::RemoteCore->new;
            # my $answers = $rc->answers(
            #     question => $text,
            #     channel  => "/networks/$network->{name}/channels/" . substr($channel, 1)
            # );
            # my @to_send = ();
            # for my $answer (@$answers) {
            #     if ($answer->{confidence} == 1) {
            #         push @to_send, ($to_me ? "${from_nick}: " : "") . $answer->{content};
            #         next;
            #     }
            #     last if @to_send > 0 || !$to_me;
            #     push @to_send, "${from_nick}: " . $answer->{content};
            # }
            # for my $text (@to_send) {
            #     $client->send_chan($channel, 'PRIVMSG', $channel, $text);
            # }
        }
    );

    $client->connect(@connection_args);
    return $client;
}

sub app {
    my $env = shift;
    my $req = Plack::Request->new($env);

    my ($network, $channel) = $req->path =~ m{/networks/([^/]+)/channels/([^/]+)$};

    unless ($IRC_CLIENTS->{$network}) {
        return [404, [], ["NETWORK NOT FOUND"]]
    }

    if ($network && $channel) {
        $channel = "#" . $channel;

        my $message_body = $req->param("message[body]");
        if ($message_body) {
            my $c = $IRC_CLIENTS->{$network};

            unless ($c->channel_list($channel)) {
                $c->send_srv("JOIN", $channel);
            }

            $c->send_chan($channel, "PRIVMSG", $channel, $message_body);
        }
    }

    return [200, [], ["OK"]]
}

sub run {
    my $port = rcv(
        port,

        message => sub {
            my ($data, $reply_port) = @_;

            if (my $client = $IRC_CLIENTS->{$data->{network}}) {
                my $channel = "#". $data->{channel};
                my $body    = $data->{body};

                unless ($client->channel_list($channel)) {
                    $client->send_srv("JOIN", $channel);
                }
                $client->send_chan($channel, "PRIVMSG", $channel, $body);
            }
        },

        reply => sub {
            my ($data, $reply_port) = @_;
            say "GOT REPLY: " . to_json($data);

            return unless $data->{to_me};

            my $client  = $IRC_CLIENTS->{$data->{network}} or return;
            my $channel = $data->{channel};
            my $body    = $data->{from} . ": " . $data->{answers}[0]{content};

            unless ($client->channel_list($channel)) {
                $client->send_srv("JOIN", $channel);
            }

            $client->send_chan($channel, "PRIVMSG", $channel, Encode::encode('utf8', $body));
        }
    );

    my $guard = grp_reg "jabbot_irc", $port;

    AnyEvent->condvar->recv;
}

1;

=head1 SYNOPSIS

Launch the frontend server

    plackup -s Twiggy -l 127.0.0.1:5000 -Ilib -MJabbot::Front::IRC -e "\&Jabbot::Front::IRC::app"

Post to the givent channel (auto-joined if not alreay joined):

    echo "message[body]=你好" | POST http://127.0.0.1:5000/networks/freenode/channels/jabbot

=cut
