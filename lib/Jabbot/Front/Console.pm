package Jabbot::Front::Console;
use common::sense;
use AnyEvent;
use AnyEvent::MP;
use AnyEvent::MP::Global;
use AnyEvent::IRC::Client;

sub run {
    configure nodeid => "jabbot_console";

    say "Jabbot Console. Hit Ctrl-C to quit.";

    my $answered = AE::cv;

    grp_reg jabbot_console => rcv
        port,
        reply => sub {
            my $data = shift;

            say "\njabbot: " . $data->{answer}{content} . "\n";
        };

    my $ask = sub {
        my $question = shift;

        my $ports = grp_get "jabbot_core" or return;

        for (@$ports) {
            snd $_, action => {
                name => 'answer',
                node => "jabbot_console",
                args => {
                    network  => "jabbot_console",
                    channel  => "jabbot_console",
                    from     => $ENV{USER} || "user",
                    to_me    => 1,
                    question => $question
                }
            };
        }
    };

    $| = 1;
    my $question_ready = AE::io *STDIN, 0, sub {
        local $_= <STDIN>;
        chomp;
        $ask->($_);
    };

    AE::cv->recv;
}

1;
