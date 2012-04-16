package Jabbot::Component;
use v5.12;

use Jabbot;
use Proc::Pidfile;
use AnyEvent;

sub daemonize {
    my $pid = fork;
    exit if $pid;

    my ($class, $cb) = @_;
    my ($shortname) = $class =~ m/::([^:]+)$/;
    $shortname = lc($shortname);

    my $pidfile = Proc::Pidfile->new(
        pidfile => Jabbot->root->file("var", "run", "jabbot-${shortname}.pid")->stringify
    );

    my $exit = AE::cv {
        undef $pidfile;
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
