package Jabbot::Plugin::en_us::Eliza;
use common::sense;
use Object::Tiny;
use Chatbot::Eliza;
use Scalar::Defer;

sub can_answer { 1 }

my $chatbot = lazy { Chatbot::Eliza->new() };

sub answer {
    my $self = shift;
    my $text = shift;
    my $ans  = $chatbot->transform($text);

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
