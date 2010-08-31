package Jabbot::Plugin;
use common::sense;
use Object::Tiny;

sub can_answer {
    die "Plugin @{[ref($_[0])]} must implement 'can_answer(\$question)' method\n";
}

sub answer {
    die "Plugin @{[ref($_[0])]} must implement 'answer(\$question)' method\n";
}

1;
