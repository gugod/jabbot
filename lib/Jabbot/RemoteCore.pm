package Jabbot::RemoteCore;
use v5.18;

use Scalar::Util qw(refaddr);

use Hijk;
use Mojo::JSON qw(encode_json decode_json);

use YAML;

sub new {
    my ($class, %params) = @_;
    $params{host} //= "localhost";
    $params{port} //= "18000";
    return bless { %params }, $class;
}

sub answers {
    my ($self, %args) = @_;
    my @answers;

    my $q = $args{q};

    my $res = Hijk::request({
        method => "GET",
        host => $self->{host},
        port => $self->{port},
        path => "/answers",
        body => encode_json({ q => $q })
    });

    die "Error: (Hijk) $res->{error}" if exists $res->{error};
    return decode_json( $res->{body} );
}

sub answer {
    my ($self, %args) = @_;
    my $res = $self->answers(%args);
    my $best = $res->{answers}[0];
    for (@{$res->{answers}}) {
        $best = $_ if $best->{score} < $_->{score};
    }
    return $best;
}

1;

__END__

A console:

perl -Ilib -MJabbot::RemoteCore -E 'while(<>) { say Jabbot::RemoteCore->new->answer(question => $_)->{body}; }'
