package Jabbot::Plugin::en_us::Eliza;
use v5.18;
use utf8;
use Object::Tiny qw(core);

use Chatbot::Eliza;

sub can_answer {
    my ($self, $text) = @_;
    if (length($text) > 2) {
        return 0.1;
    }
    return 0;
}

sub answer {
    my ($self, $text) = @_;

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
