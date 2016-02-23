package Jabbot::RemoteCore;
use v5.18;

use Mojo::UserAgent;

use Jabbot;
use Jabbot::Types qw(JabbotMessage);

sub new {
    my ($class, %params) = @_;
    $params{cored} = Jabbot->config->{cored}{listen} // "http://localhost:18000";
    return bless { %params }, $class;
}

sub answers {
    my ($self, $message) = @_;
    JabbotMessage->assert_valid($message);
    my $ua = Mojo::UserAgent->new;
    my $tx = $ua->get(
        ($self->{cored} . "/answers"),
        {},
        json => $message
    );
    return $tx->res->json();
}

sub answer {
    my ($self, $message) = @_;
    my $res = $self->answers($message);
    my @all_answers = sort { $b->{score} <=> $a->{score} } @{$res->{answers}};
    my @best_answers = grep { $_->{score} == $all_answers[0]{score} } @all_answers;
    my $best = $best_answers[rand(@best_answers)];
    return $best;
}

1;

__END__

A console:

perl -Ilib -MJabbot::RemoteCore -E 'while(<>) { say Jabbot::RemoteCore->new->answer(question => $_)->{body}; }'
