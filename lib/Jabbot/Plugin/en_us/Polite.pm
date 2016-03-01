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
    return {
        body  => "you are welcome.",
        score => 0.8
    }
}

1;
