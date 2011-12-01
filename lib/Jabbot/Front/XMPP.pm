package Jabbot::Front::XMPP;
use v5.12;
use AnyEvent;
use AnyEvent::XMPP::Client;
use AnyEvent::MP;
use AnyEvent::MP::Global;
use Jabbot;

sub ask {
    my ($message, $cb) = @_;

    my $ports = grp_get "jabbot-core" or return;

    my $from = $message->from;
    $from =~ s{/.+$}{};

    my $to = $message->to;
    $to =~ s{/.+$}{};

    my $m = {
        question => $message->body,
        network  => "xmpp-$to",
        channel  => $from,
        from     => $from,
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
                    $client->send_message($reply->{answer}{content}, $message->from, $account->jid);
                }
            );
        },

        contact_request_subscribe => sub {
            my ($client, $account, $roster, $contact, $message) = @_;
            $contact->send_subscribed;
        },
#        error => sub {
#            my ($client, $account, $error) = @_;
#            require YAML;
#            say YAML::Dump(\@_);
#        }
    );

    $cl->start;

    AE::cv->wait;

}

1;
