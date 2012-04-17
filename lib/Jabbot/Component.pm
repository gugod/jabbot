package Jabbot::Component;
use v5.12;

use Jabbot;
use Proc::PID::File;
use Path::Class;
use AnyEvent;

sub daemonize {
    my $pid = fork;
    exit if $pid;

    my ($class, $cb) = @_;
    my ($shortname) = $class =~ m/::([^:]+)$/;
    $shortname = lc($shortname);

    my $pidfile = Proc::PID::File->new(
        dir     => dir(Jabbot->root, "var", "run")->stringify,
        name    => $shortname
    );

    if ($pidfile->alive) {
        die "${shortname}is already running";
        exit;
    }

    $pidfile->touch;

    my $exit = AE::cv {
        say "EXIT $shortname";
    };

    my $w1 = AE::signal INT  => $exit;
    my $w2 = AE::signal TERM => $exit;

    if (ref($cb) eq 'CODE') {
        $cb->();
    }

    $exit->recv;
};


1;
