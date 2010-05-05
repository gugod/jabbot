package Jabbot::Plugin;
use common::sense;
use Object::Tiny;

sub can_answer {
    die "Plugin should implement 'can_answer($question)' method\n";
}

sub answer {
    die "Plugin should implement 'answer($question)' method\n";
}

1;
