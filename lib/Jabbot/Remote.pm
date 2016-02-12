package Jabbot::Remote;
use Moo;
use Mojo::JSON qw(encode_json);
use URI;


has target => (
    is => "ro"
);

sub post {
    my ($self, $opt) = @_;

    my $uri = URI->new( Jabbot->config->{$self->target}->{listen} );
    my $res = Hijk::request({
        method => "POST",
        host   => $uri->host,
        port   => $uri->port,
        path   => "/",
        body   => encode_json($opt),
    });
    return $res;
}

1;

__END__

Jabbot::Remote->new( target => "ircbot" )->post({ ... });
