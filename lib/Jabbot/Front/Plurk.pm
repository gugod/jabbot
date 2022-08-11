package Jabbot::Front::Plurk;
use v5.36;

use Jabbot;
use Jabbot::Types qw(JabbotMessage);

use Encode qw(encode_utf8);

use OAuth::Lite::Token;
use OAuth::Lite::Consumer;

use Mojo::JSON qw(decode_json);
use Mojolicious::Lite;

my $config = Jabbot->config->{plurk};

sub plurk_this {
    my $message = shift;
    JabbotMessage->assert_valid($message);

    my $auth = OAuth::Lite::Consumer->new(
        consumer_key    => $config->{consumer_key},
        consumer_secret => $config->{consumer_secret},
        site           => 'https://www.plurk.com',
    );
    my $access_token = OAuth::Lite::Token->new(
        token => $config->{access_token},
        secret => $config->{access_token_secret},
    );

    my $res = $auth->request(
        method => 'POST',
        url => 'https://www.plurk.com/APP/Timeline/plurkAdd',
        token => $access_token,
        params => {
            content   => encode_utf8($message->{body}),
            qualifier => ':',
        }
    );

    my $body = decode_json($res->decoded_content);
    return $body->{plurk_id};
}

get '/' => sub {
    my $c = shift;
    $c->render(json => {
        name  => "jabbot-plurkd",
    });
};

post '/' => sub {
    my $c = shift;
    my $res = {};
    my @error;
    my $req = decode_json( $c->req->body );
    if (!defined($req->{body})) {
        push @error, "\"body\" is missig";
    }
    my $plurk_id = plurk_this({
        network => "plurk",
        channel => $config->{username},
        author  => $config->{username},
        body => $req->{body},
    });
    if ($plurk_id) {
        $res->{plurk_id} = $plurk_id;
    } else {
        $res->{error} = "failed plurking";
    }
    $c->render(json => $res);
};

app->start;
