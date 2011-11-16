package Jabbot::Back::Memory;
use common::sense;
use Giddy;
use AnyEvent;
use AnyEvent::MP;
use ANyEvent::MP::Global;

configure profile => "jabbot-memory";

sub run {
    AE::cv->recv;
}

1;
