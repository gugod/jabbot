package Jabbot::Memory;
# ABSTRACT: client interface to jabbot-memoryd

use v5.18;
use Object::Tiny;

use Mojo::UserAgent;

use Jabbot;

use constant SERVER_URI_BASE => "http://" . ( Jabbot->config->{host} // "localhost" ) . ":" . ( Jabbot->config->{port} // 18002 );

sub set {
    my ($self, $collection, $key, $value) = @_;
    my $ua = Mojo::UserAgent->new;
    $ua->put(
        SERVER_URI_BASE . "/${collection}/{$key}",
        {},
        $value
    );
}

sub get {
    my ($self, $collection, $key) = @_;
    my $ua = Mojo::UserAgent->new;
    my $tx = $ua->get(SERVER_URI_BASE . "/${collection}/{$key}");
    if (my $res = $tx->success) {
        return $res->body;
    } else {
        return undef;
    }
}

1;
