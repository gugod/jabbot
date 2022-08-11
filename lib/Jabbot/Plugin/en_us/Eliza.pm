package Jabbot::Plugin::en_us::Eliza;
use v5.36;
use utf8;
use Object::Tiny qw(core);

use List::Util qw(first);
use Chatbot::Eliza;

sub can_answer {
    my ($self, $message) = @_;
    my $text = $message->{body};
    if (length($text) > 2) {
        return 0 if first { /\A \p{Letter} \z/x && !/\A \p{Script=Latin} \z/x  } split("", $text);
        return 0.1;
    }
    return 0;
}

sub answer {
    my ($self, $message) = @_;
    my $text = $message->{body};
    $self->{chatbot} ||= Chatbot::Eliza->new();
    my $ans  = $self->{chatbot}->transform($text);

    if ($text =~ /thou|thy|thee|thine/) {
        $ans =~ s/have you/hast thou/gi;
        $ans =~ s/your/thy/gi;
        $ans =~ s/yours/thine/gi;
        $ans =~ s/you/thou/gi;
    }

    return {
        body  => $ans,
        score => 0,
    }
}

1;
