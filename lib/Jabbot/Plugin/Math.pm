package Jabbot::Plugin::Math;
use v5.36;
use Object::Tiny qw(core);

use Try::Tiny;
use Math::Expression::Evaluator;

sub can_answer {
    my ($self, $message) = @_;
    my $text = $message->{body};
    
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
        body  => $val,
        score => 1,
    };
}

1;
