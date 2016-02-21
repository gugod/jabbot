package Jabbot::Back::Memory;
use strict;
our $VERSION = "0.1";

use Time::HiRes;
use UnQLite;
use Mojo::JSON;
use Mojolicious::Lite;
use Mojo::UserAgent;

sub __open_db {
    state $cache = {};
    my ($collection) = @_;
    my $c = $cache->{$collection} ||= {
        db => UnQLite->open(Jabbot->config->{memoryd}{database_root}."/${collection}.db", UnQLite::UNQLITE_OPEN_READWRITE|UnQLite::UNQLITE_OPEN_CREATE)
    };
    $c->{last_used} = time;
    return $c->{db};
}

sub open_db_and_get {
    my ($collection, $key) = @_;
    my $db = __open_db($collection);
    return $db->kv_fetch($key);
}

sub open_db_and_set {
    my ($collection, $key, $value) = @_;
    my $db = __open_db($collection);
    return $db->kv_store($key,$value);
}

get '/' => sub {
    my $c = shift;
    $c->render(json => {
        name => "jabbot-memoryd",
        version => $VERSION,
    });
};

get '/:collection/:key' => sub {
    my $c = shift;
    my $k = $c->param('key');

    my $begin_t = Time::HiRes::time;
    my $v = open_db_and_get($c->param('collection'), $k);
    my $took = Time::HiRes::time - $begin_t;

    $c->res->headers->append("X-Jabbot-Memoryd", Mojo::JSON::encode_json({ _took => $took }));
    $c->render(data => $v);
};

put '/:collection/:key' => sub {
    my $c = shift;
    my $k = $c->param('key');
    my $v = $c->req->body;

    my $begin_t = Time::HiRes::time;

    open_db_and_set($c->param('collection'), $k, $v);

    my $took = Time::HiRes::time - $begin_t;

    $c->render(json => {
        _took => $took,
        success => 1,
    });
};

app->start;
