package Jabbot::Plugin::Echo;
use v5.18;
use Object::Tiny qw(core);

sub can_answer {
    1;
}

sub answer {
    my ($self, $text, $message) = @_;

    return {
        confidence => 0.9,
        content => $text
    }
}

1;
