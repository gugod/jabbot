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

    while( <> ) {
        chomp;

        my $reply = $jabbot->answer(question => $_);

        if ($reply) {
            say $reply->{answer}{content};
        }
        else {
            say "NO ANSWER";
        }

        print "jabbot> ";
    }
}

1;
