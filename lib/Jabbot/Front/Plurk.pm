use v5.18;

package Jabbot::Front::Plurk;
use strict;
use warnings;

use Jabbot;
use Jabbot::Types qw(JabbotMessage);
use PlurkPoster;

use Mojo::JSON qw(decode_json);
use Mojolicious::Lite;

my $config = Jabbot->config->{plurk};

sub plurk_this {
    state $plurk_poster = do {
        my $p = PlurkPoster->new(
            username => $config->{username},
            password => $config->{password},
        );
        $p->login;
        $p;
    };
    my $message = shift;
    JabbotMessage->assert_valid($message);
    my $plurk_id;
    eval {
        $plurk_id = $plurk_poster->post($message->{body});
        1;
    };
    return $plurk_id;
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
