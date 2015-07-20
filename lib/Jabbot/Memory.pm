package Jabbot::Memory;
# ABSTRACT: client interface to jabbot-memoryd

use v5.18;
use Object::Tiny;

use Mojo::UserAgent;

my $server_uri_base = "http://localhost:18002";

sub set {
    my ($self, $collection, $key, $value) = @_;
    my $ua = Mojo::UserAgent->new;
    $ua->put(
        "${server_uri_base}/${collection}/{$key}",
        {},
        $value
    );
}

sub get {
    my ($self, $collection, $key) = @_;
    my $ua = Mojo::UserAgent->new;
    my $tx = $ua->get("${server_uri_base}/${collection}/{$key}");
    if (my $res = $tx->success) {
        return $res->body;
    } else {
        return undef;
    }
}

1;
