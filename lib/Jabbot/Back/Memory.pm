package Jabbot::Back::Memory;
use common::sense;
use Giddy;
use AnyEvent;
use AnyEvent::MP;
use ANyEvent::MP::Global;

sub run {
    configure profile => "jabbot-memory";
    AE::cv->recv;
}

1;
