package Jabbot::Plugin::Echo;
use v5.36;
use Object::Tiny;

sub can_answer {
    0.5;
}

sub answer {
    my ($self, $message) = @_;
    my $text   = $message->{body};

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
