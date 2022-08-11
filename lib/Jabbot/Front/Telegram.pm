package Jabbot::Front::Telegram;
use v5.36;

use Jabbot;
use Jabbot::RemoteCore;

use Encode qw(encode_utf8);
use List::Util qw(max);

use Mojo::JSON qw(decode_json);
use Mojo::Util;
use Mojo::IOLoop;
use WWW::Telegram::BotAPI;

my $API_TELEGRAM = WWW::Telegram::BotAPI->new (token => Jabbot->config->{telegram}{token}, async => 1);

my $CHATS = {};

sub send_reply {
    state $jabbot = Jabbot::RemoteCore->new();
    my ($chat_id, $text) = @_;

    my $answer = $jabbot->answer({
        body    => $text,
        network => "telegram",
        channel => "chat_id:$chat_id",
        author  => "chat_id:$chat_id",
    });

    if ($answer) {
        my $reply_text = $answer->{body};

        $API_TELEGRAM->api_request(
            sendMessage => {
                chat_id => $chat_id,
                text    => $reply_text,
            }, sub {
                my ($ua, $tx) = @_;
                return unless $tx->result->is_success;
            }
        );
    }
}

sub get_updates {
    my $RECV = {};
    state $max_update_id = -2;

    $API_TELEGRAM->api_request(
        'getUpdates',
        { offset => ($max_update_id+1), timeout => 12 },
        sub {
            my ($ua, $tx) = @_;
            return unless $tx->result->is_success;

            my $res = decode_json( $tx->res->body );
            for (@{$res->{result}}) {
                $max_update_id = max($max_update_id, $_->{update_id});

                $RECV->{updates}{ $_->{update_id} } = { update => $_ };

                my $chat_id = $_->{message}{chat}{id};
                $CHATS->{ $chat_id } //= {
                    target => $_->{message}{chat},
                    messages => []
                };
                my $message_log = $CHATS->{ $chat_id }{messages};

                my %m = %{$_->{message}};
                delete @m{"from", "chat"};
                push @$message_log, \%m;

                if ((my $alength = @$message_log) > 10) {
                    splice(@$message_log, 0, $alength - 10);
                }

                send_reply( $chat_id, $_->{message}{text} );
            }
        }
    );
}

$API_TELEGRAM->api_request(
    'getMe',
    sub {
        my ($ua, $tx) = @_;
        my $res = $tx->result;
        die Mojo::Util::dumper($tx->error) unless $res->is_success;
        my $interval = Jabbot->config->{telegram}{poll_interval} // 60;
        Mojo::IOLoop->recurring( $interval  => \&get_updates );
    }
);


use Mojolicious::Lite;

get '/' => sub {
    my $c = shift;
    $c->render(json => {
        name  => "jabbot-telegramd",
        chats => $CHATS,
    });
};

post '/' => sub {
    my $c = shift;
    my $res = {};
    my @error;
    my $req = decode_json( $c->req->body );
    if (!defined($req->{chat_id})) {
        push @error, "\"chat_id\" is missig";
    }
    if (!defined($req->{text})) {
        push @error, "\"text\" is missig";
    }
    if ($req->{chat_id} && !exists($CHATS->{$req->{chat_id}})) {
        push @error, "\"chat_id\" $req->{chat_id} is unknown";
    }
    
    if (!@error) {
        $API_TELEGRAM->api_request(
            sendMessage => {
                chat_id => $req->{chat_id},
                text    => $req->{text},
            }, sub {
                my ($ua, $tx) = @_;
                return unless $tx->result->success;
            }
        );
    } else {
        $res->{error} = \@error;
    }

    $c->render(json => $res);
};

# Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
app->start;
