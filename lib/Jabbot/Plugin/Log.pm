package Jabbot::Plugin::Log;
use v5.18;

use Object::Tiny;

use Jabbot;
use Jabbot::Memory;
use Time::Moment;

sub can_answer {
    my ($self, $message) = @_;

    my $now = Time::Moment->now_utc;
    my $key = join("-", $message->{network}, $message->{channel}, $now->to_string);

    my $mem = Jabbot::Memory->new;
    $mem->set("log", $key, $message->{body});

    return 0;
}

sub answer {}

1;
