package Jabbot::RemoteCore;
use v5.18;

use Encode qw(decode_utf8 encode_utf8);
use Mojo::UserAgent;

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

    $q = decode_utf8($q) unless Encode::is_utf8($q);

    my $ua = Mojo::UserAgent->new;
    my $tx = $ua->get(
        ("http://" . $self->{host} . ":" . $self->{port} . "/answers"),
        {},
        json => {
            q => $q
        }
    );
    return $tx->res->json();
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
