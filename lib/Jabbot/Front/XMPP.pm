package Jabbot::Front::XMPP;
use 5.012;
use utf8;
use JSON qw(decode_json encode_json);
use Encode qw(encode_utf8 decode_utf8);
use AnyEvent;
use AnyEvent::XMPP::Client;
use AnyEvent::MP;
use AnyEvent::MP::Global;
use Jabbot;

sub ask {
    my ($message, $cb) = @_;

    my $ports = grp_get "jabbot-core" or return;

    my $m = {
        question => $message->body,
        network  => "xmpp-" . $message->to,
        channel  => $message->from,
        from     => $message->from,
        to_me    => 1
    };

    snd $ports->[0], action => { name => "answer", args => $m }, port {
        my (undef, $data) = @_;

        $cb->($data);
    };

    return;
}

sub run {
    configure;

    my $cl = AnyEvent::XMPP::Client->new();

    $cl->set_accounts( Jabbot->config->{xmpp}{accounts} );

    $cl->reg_cb(
        message => sub {
            my ($client, $account, $message) = @_;

            ask(
                $message,
                sub {
                    my ($reply) = @_;
                    my $msg = $message->make_reply();
                    $msg->add_body( $reply->{answer}{content} );
                    $client->send_message($msg);
                }
            );
        },

        contact_request_subscribe => sub {
            my ($client, $account, $roster, $contact, $message) = @_;
            $contact->send_subscribed;
        }
    );

    $cl->start;

    AE::cv->wait;

}

1;
