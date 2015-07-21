package Jabbot::Front::Console;
use v5.18;
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

        my $reply = $jabbot->answer(q => $_);

        if ($reply) {
            say $reply->{body};
        }
        else {
            say "NO ANSWER";
        }

        print "jabbot> ";
    }
}

1;
