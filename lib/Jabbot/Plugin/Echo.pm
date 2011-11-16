package Jabbot::Plugin::Echo;
use Jabbot::Plugin;

sub can_answer {
    1;
}

sub answer {
    my ($text, $message) = @args;

    return {
        confidence => 1,
        content => $text
    }
}

1;
