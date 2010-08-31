package Jabbot::Plugin;
use common::sense;
use Object::Tiny;
use B::Hooks::Parser;

sub import {
    my $caller = caller;
    B::Hooks::Parser::inject($_) for reverse(
        'use parent "Jabbot::Plugin";',
        'use common::sense;',
        'use self;'
    );
}

sub can_answer {
    die "Plugin @{[ref($_[0])]} must implement 'can_answer(\$question)' method\n";
}

sub answer {
    die "Plugin @{[ref($_[0])]} must implement 'answer(\$question)' method\n";
}

1;
