package Jabbot::Plugin::en_us::Polite;
use Jabbot::Plugin;

sub can_answer {
    my ($text) = @args;

    if ($text =~ /(thank(s|\s+you)|\bGJ\b)/i) {
        return 1;
    }
    return 0;
}

sub answer {
    return {
        content    => "you are welcome.",
        confidence => 0.5
    }
}

1;
