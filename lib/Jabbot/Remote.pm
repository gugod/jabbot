package Jabbot::Remote;
use Moo;
use Mojo::UserAgent;
use Mojo::JSON qw(encode_json);
use URI;
use Jabbot;
use Hijk;

has target => (
    is => "ro"
);

sub post {
    my ($self, $opt) = @_;
    my $uri = Jabbot->config->{$self->target}->{listen};
    my $tx = Mojo::UserAgent->new->post(
        $uri ,
        {Accept => '*/*'} => json => $opt );
    my $res = $tx->result->json;
    return $res;
}

1;

__END__

Jabbot::Remote->new( target => "ircbot" )->post({ ... });
