package Jabbot::Plugin::en_us::Polite;
use Jabbot::Plugin;

sub can_answer {
    my ($text) = @args;

    return $text =~ /thank(s|\s+you)/i;
}

sub answer {
    return {
        content    => "you are welcome.",
        confidence => 0.5
    }
}

1;
