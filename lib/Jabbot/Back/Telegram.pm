package Jabbot::Back::Telegram;
use strict;
our $VERSION = "0.1";

use Time::HiRes;
use Mojo::JSON;
use Mojo::IOLoop;
use Mojolicious::Lite;
use Mojo::UserAgent;

use Encode qw(encode_utf8);
use List::Util qw(max);

use WWW::Telegram::BotAPI;

get '/' => sub {
    my $c = shift;
    $c->render(json => {
        name => "jabbot-telegramd",
        version => $VERSION,
    });
};

app->start;
