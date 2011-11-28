package Jabbot::Plugin::Log;
use Jabbot::Plugin;
use Jabbot;
use DateTime;

sub can_answer {
    my ($text, $message) = @args;

    say "Logging: $text";

    my $today = DateTime->today;
    my $name = join("-", $message->{network}, $message->{channel}, $today->year, $today->month, $today->day);

    my %m = %$message;
    delete $m{channel};
    delete $m{network};

    Jabbot->memory->update("log", $name, { '$push' => { messages => \%m } }, { upsert => 1 });

    return;
}

sub answer {}

1;
