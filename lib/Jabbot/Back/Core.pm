package Jabbot::Back::Core;
use strict;

use Jabbot;
use Jabbot::Core;
use Time::HiRes;

use Mojolicious::Lite;

my $VERSION = "0.0.1";
my $CORE = Jabbot::Core->new;

get '/' => sub {
    my $c = shift;
    $c->render(json => {
        name     => "jabbot-cored",
        version  => $VERSION,
        plugins  => [ map { ref($_) } @{ $CORE->{plugins} } ],
        services => $CORE->{services},
    });
};

get '/answers' => sub {
    my $c = shift;
    my $message = $c->req->json();

    my $begin_t = Time::HiRes::time;
    my $answers = $CORE->answers($message);
    my $took = Time::HiRes::time - $begin_t;

    $c->render(json => {
        _took   => $took,
        answers => $answers
    });
};

post '/services' => sub {
    my $c = shift;

    my $srv = $c->req->json(); # { "name": "...", "host", "...", "port": "..." }

    my $begin_t = Time::HiRes::time;

    my $success = 0;
    if ( defined($srv->{name}) && defined($srv->{host}) && defined($srv->{port}) ) {
        $CORE->register_service($srv);
        $success = 1;
    }

    my $took = Time::HiRes::time - $begin_t;

    $c->render(json => {
        _took   => $took,
        success => $success
    });
};

app->start;

