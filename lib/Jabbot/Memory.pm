package Jabbot::Memory;
# ABSTRACT: client interface to jabbot-memoryd

use v5.36;
use Object::Tiny;

use Mojo::UserAgent;
use Mojo::Util 'url_escape', 'encode', 'decode';

use Jabbot;

use constant SERVER_URI_BASE => Jabbot->config->{memoryd}{listen} // "http://127.0.0.1:18002";

sub set {
    my ($self, $collection, $key, $value) = @_;

    $value = encode 'UTF-8', $value;

    my $ua = Mojo::UserAgent->new;
    $ua->put(
        join("/", SERVER_URI_BASE, url_escape($collection), url_escape($key)),
        {},
        $value
    );
}

sub get {
    my ($self, $collection, $key) = @_;
    my $ua = Mojo::UserAgent->new;
    my $tx = $ua->get( join("/", SERVER_URI_BASE, url_escape($collection), url_escape($key)) );
    if (my $res = $tx->success) {
        return decode 'UTF-8', $res->body;
    } else {
        return undef;
    }
}

1;
