package Jabbot::Plugin::en_us::Polite;
use strict;
use warnings;
use Object::Tiny;

sub can_answer {
    my ($self, $message) = @_;
    my $text = $message->{body};

    if ($text =~ /(thank(s|\s+you)|\bGJ\b)/i) {
        return 1;
    }
    return 0;
}

sub answer {
    my ($self, $message) = @_;
    return {
        body  => "you are welcome.",
        score => 5 / length($message->{body}),
    }
}

1;
