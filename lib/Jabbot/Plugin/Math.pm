package Jabbot::Plugin::Math;
use common::sense;
use Object::Tiny;
use Try::Tiny;
use Math::Expression::Evaluator;

sub can_answer {
    my ($self, $text) = @_;

    $text =~ s/^\s+//;
    $text =~ s/\s*\?*\s*$//;
    return if $text !~ m{[\+\-\*\/]};

    try {
        my $m = Math::Expression::Evaluator->new;
        $self->{tree} = $m->parse($text);
    };
    $self->{tree};
}

sub answer {
    my ($self) = @_;
    my $tree = $self->{tree};
    my $val;

    try {
        $val = $tree->val();
    } catch {
        $val = "Invalid math expression"
    };

    return {
        content => $val,
        confidence => 1
    };
}

1;
