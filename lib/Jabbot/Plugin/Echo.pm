package Jabbot::Plugin::Echo;
use v5.18;
use strict;
use warnings;
use Object::Tiny;

sub can_answer {
    1;
}

sub answer {
    my ($self, $text, $message) = @_;

    my $chance = int(rand()*10);
    my $emotion = {
        8 => "...?",
        7 => " XD",
        6 => " !!",
        5 => " :D",
        4 => " :)",
        3 => " :-P",
        2 => " .... ???!",
    }->{$chance} || "";

    if ($emotion) {
        $text = "$text $emotion";
    }

    return {
        score => 0,
        body  => $text
    }
}

1;
