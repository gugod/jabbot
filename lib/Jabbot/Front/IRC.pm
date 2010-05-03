package Jabbot::Front::IRC;
use common::sense;
use JSON qw(decode_json encode_json);
use Plack::Request;
use Jabbot::RemoteCore;
use AnyEvent;
use AnyEvent::IRC::Client;

sub init_irc_client {
    my ($server) = @_;

    my $client = AnyEvent::IRC::Client->new;
    $client->reg_cb(registered => sub { say STDERR "I'm in!"; });

    $client->connect($server, 6667, { nick => 'jabbot' });
    return $client;
}

my $IRC_CLIENTS = {};

{
    my $servers = {
        freenode => "chat.freenode.net"
    };

    for (qw(freenode)) {
        $IRC_CLIENTS->{$_} = init_irc_client($servers->{$_})
    }
}

sub app {
    my $env = shift;
    my $req = Plack::Request->new($env);

    my ($network, $channel) = $req->path =~ m{/networks/(\w+)/channels/(\w+)$};

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
