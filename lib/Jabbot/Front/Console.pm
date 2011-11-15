package Jabbot::Front::Console;
use v5.12;
use common::sense;
use AnyEvent;
use Jabbot::RemoteCore;

sub run {
    say "Jabbot Console. Hit Ctrl-C to quit.";
    binmode STDIN, ":utf8";
    binmode STDOUT, ":utf8";

    my $jabbot = Jabbot::RemoteCore->new;

    local $| = 1;

    print "jabbot> ";

    while( $_ = <>) {
        chomp;
        my $answer = $jabbot->answer(question => $_);

        if ($answer) {
            say $answer->{content}
        }
        else {
            say "NO ANSWER";
        }

        print "jabbot> ";
    }

    AE::cv->recv;
}

1;
