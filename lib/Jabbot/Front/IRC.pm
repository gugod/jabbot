package Jabbot::Front::IRC;
use common::sense;
use JSON qw(decode_json encode_json);
use Plack::Request;
use Jabbot;
use Jabbot::RemoteCore;
use AnyEvent;
use AnyEvent::IRC::Client;

sub init_irc_client {
    my ($network) = @_;

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

            return unless $to_me;

            my $rc = Jabbot::RemoteCore->new;
            my $answer = $rc->answer(question => $text, channel => $channel);

            if ($answer) {
                return if $answer->{confidence} == 0 && rand(10) > 8;

                my $from_nick = AnyEvent::IRC::Util::prefix_nick($ircmsg->{prefix}) || "";
                $client->send_chan($channel, 'PRIVMSG', $channel, "${from_nick}: $answer->{content}");
            }
        }
    );

    $client->connect($network->{server},
                     $network->{port} || 6667,
                     { nick => $network->{nick} });
    return $client;
}

my $IRC_CLIENTS = {};

{
    my $networks = Jabbot->config->{irc}{networks};
    for (keys %$networks) {
        $networks->{$_}{nick} ||= (Jabbot->config->{nick} || "jabbot_$$");
        $IRC_CLIENTS->{$_} = init_irc_client($networks->{$_})
    }
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

1;

=head1 SYNOPSIS

Launch the frontend server

    plackup -s Twiggy -l 127.0.0.1:5000 -Ilib -MJabbot::Front::IRC -e "\&Jabbot::Front::IRC::app"

Post to the givent channel (auto-joined if not alreay joined):

    echo "message[body]=你好" | POST http://127.0.0.1:5000/networks/freenode/channels/jabbot

=cut
