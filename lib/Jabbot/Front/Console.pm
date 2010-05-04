package Jabbot::Front::Console;
use common::sense;
use Jabbot::RemoteCore;
use Term::ReadLine;

sub run {
    say "Jabbot Console. Hit Ctrl-C to quit.";

    my $j = Jabbot::RemoteCore->new;
    my $term = Term::ReadLine->new('jabbot');
    my $prompt = "\njabbot> ";
    my $OUT = $term->OUT || \*STDOUT;
    while ( defined ($_ = $term->readline($prompt)) ) {
        my $ans = $j->answer(question => $_);
        warn $@ if $@;
        say $OUT $ans->{content} unless $@;

        $term->addhistory($_) if /\S/;
    }
}

&run;
