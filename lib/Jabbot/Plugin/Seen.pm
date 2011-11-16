package Jabbot::Plugin::Seen;
use Jabbot::Plugin;
use Jabbot;
use AnyEvent;

sub can_answer {
    my ($text, $message) = @args;

    if ($text =~ /seen\s+(\W+)\s*\?$/) {
        $self->{nick} = $1;
        return 1;
    }

    Jabbot->memory->set("seen", $message->{from}, { time => time, message => $message });
    return 0;
}

sub answer {
    my ($text) = @args;
    my $nick = $self->{nick};

    my $ans = AE::cv;
    Jabbot->memory->get("seen", $nick, $ans);

    return $ans->recv;
}

1;
