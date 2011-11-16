package Jabbot::Plugin::Seen;
use Jabbot::Plugin;
use Jabbot;

sub can_answer {
    my ($text, $message) = @args;

    Jabbot->memory->set("seen", $message->{from}, { time => time, message => $message });
    return 0;
}

sub answer {
}

1;
