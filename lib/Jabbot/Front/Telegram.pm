use v5.18;

package Jabbot::Front::Telegram;
use strict;
use warnings;

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
    my $reply_text = $answer->{body};

    $API_TELEGRAM->api_request(
        sendMessage => {
            chat_id => $chat_id,
            text    => $reply_text,
        }, sub {
            my ($ua, $tx) = @_;
            return unless $tx->success;
            say encode_utf8 ">> $reply_text";
        }
    );
}

sub get_updates {
    my $RECV = {};
    state $max_update_id = -1;

    $API_TELEGRAM->api_request(
        'getUpdates',
        { offset => $max_update_id + 1 },
        sub {
            my ($ua, $tx) = @_;
            return unless $tx->success;

            say time . ": " . $tx->res->body;

            my $res = decode_json( $tx->res->body );
            for (@{$res->{result}}) {
                $RECV->{updates}{ $_->{update_id} } = { update => $_ };
                $max_update_id = max($max_update_id, $_->{update_id});

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

                say encode_utf8 "<< $_->{message}{text}";
                send_reply( $chat_id, $_->{message}{text} );
            }

            say "="x40;
        }
    );
}

$API_TELEGRAM->api_request(
    'getMe',
    sub {
        my ($ua, $tx) = @_;
        die Mojo::Util::dumper($tx->error) unless $tx->success;
        say "getMe: " . $tx->res->body;

        my $interval = Jabbot->config->{telegram}{poll_interval} // 15;
        say "poll interval = $interval";

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
                return unless $tx->success;
            }
        );
    } else {
        $res->{error} = \@error;
    }

    $c->render(json => $res);
};

# Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
app->start;

