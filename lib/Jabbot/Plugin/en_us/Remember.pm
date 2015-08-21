package Jabbot::Plugin::en_us::Remember;
use v5.18;
use Object::Tiny qw(core);

use Jabbot::Memory;
use List::UtilsBy qw(max_by);

sub can_answer {
    my ($self, $text) = @_;
    my ($op, $k) = $text =~ /\A \s* (remember|recall) (?: \s|\p{Punctuation}) (.+) \z/x;
    if (defined($op) && defined($k)) {
        $self->{stash} = {
            op => $op,
            k  => $k
        };
        return 1;
    }
    return 0;
}

sub answer {
    my ($self, $text) = @_;
    my $proc = "process_" . $self->{stash}{op};
    my $procsub = $self->can($proc) or die "Unknown processor: $proc";
    return $procsub->($self, $self->{stash}{k});
}

my $MEMORY = { doc => {}, token => {} };

sub tokenize {
    my $text = shift;
    my @t = grep { defined($_) && $_ ne "" } split /\P{Letter}+/, $text;
    return \@t;
}

sub process_remember {
    my ($self, $k) = @_;

    my $id = (keys %{$MEMORY->{doc}}) + 1;
    $MEMORY->{doc}{$id} = $k;

    for my $t (@{ tokenize($k) }) {
        push @{ $MEMORY->{token}{$t} }, {
            doc_id => $id
        };
    }
    return;
}

sub process_recall {
    my ($self, $k) = @_;
    my $score = {};
    for my $t (@{ tokenize($k) }) {
        for (@{ $MEMORY->{token}{$t} }) {
            $score->{ $_->{doc_id} }++;
        }
    }
    my $best = max_by { $score->{$_} } keys %$score;
    my $doc = $MEMORY->{doc}{$best};
    return {
        score => 1,
        body => $doc,
    }
}

1;

__END__

=begin NOTES

Syntax:
    "remember,"  + SPACES + TEXT
    "recall,"    + SPACES + TEXT

Examples:

    jabbot: remember, The force will be with you.
    jabbot: remember, diaspora is a decentralized SNS system.
    jabbot: remember, git is a decentralized version control system

    jabbot: recall, The force
    jabbot> The force will be with you

    jabbot: recall, decentralized system
    jabbot> diaspora is a decentralized SNS system.
    jabbot> git is a decentralized version control system.

=cut
