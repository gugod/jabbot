package Jabbot::Plugin::en_us::Eliza;
use common::sense;
use Object::Tiny;
use Chatbot::Eliza;
use self;

sub can_answer {
    my ($text) = @args;
    return length($text) > 2;
}

sub answer {
    my ($text) = @args;

    $self->{chatbot} ||= Chatbot::Eliza->new();
    my $ans  = $self->{chatbot}->transform($text);

    if ($text =~ /thou|thy|thee|thine/) {
        $ans =~ s/have you/hast thou/gi;
        $ans =~ s/your/thy/gi;
        $ans =~ s/yours/thine/gi;
        $ans =~ s/you/thou/gi;
    }

    return {
        content    => $ans,
        confidence => 0
    }
}

1;
