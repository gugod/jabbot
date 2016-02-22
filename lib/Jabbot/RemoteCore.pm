package Jabbot::RemoteCore;
use v5.18;

use Encode qw(decode_utf8 encode_utf8);
use Mojo::UserAgent;
use Jabbot;

sub new {
    my ($class, %params) = @_;
    $params{cored} = Jabbot->config->{cored}{listen} // "http://localhost:18000";
    return bless { %params }, $class;
}

sub answers {
    my ($self, %args) = @_;
    my @answers;

    my $q = $args{q};

    $q = encode_utf8($q) if Encode::is_utf8($q);

    my $ua = Mojo::UserAgent->new;
    my $tx = $ua->get(
        ($self->{cored} . "/answers"),
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
    my @all_answers = sort { $b->{score} <=> $a->{score} } @{$res->{answers}};
    my @best_answers = grep { $_->{score} == $all_answers[0]{score} } @all_answers;
    my $best = $best_answers[rand(@best_answers)];
    return $best;
}

1;

__END__

A console:

perl -Ilib -MJabbot::RemoteCore -E 'while(<>) { say Jabbot::RemoteCore->new->answer(question => $_)->{body}; }'
