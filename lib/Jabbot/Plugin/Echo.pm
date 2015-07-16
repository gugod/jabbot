package Jabbot::Plugin::Echo;
use v5.18;
use Object::Tiny qw(core);

sub can_answer {
    1;
}

sub answer {
    my ($self, $text, $message) = @_;

    return {
        score   => 1,
        content => $text
    }
}

1;
