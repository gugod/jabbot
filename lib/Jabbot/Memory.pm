package Jabbot::Memory;
use common::sense;
use self;
use AnyEvent;
use AnyEvent::MP;
use AnyEvent::MP::Global;

sub get {
    my ($collection, $key, $cb) = @args;
    return unless $collection && $key && $cb;
    my $ports = grp_get "jabbot-memory" or return;

    my $value = AE::cv;
    $value->cb(sub {$cb->($_[0]->recv) });

    snd $ports->[0], "get" => "person", "gugod", port {
        $value->send(@_);
    };
}

sub set {
    my ($collection, $key, $value) = @args;
    return unless $collection && $key && defined($value);
    my $ports = grp_get "jabbot-memory" or return;

    for (@$ports) {
        snd $_, "set" => $collection, $key, $value;
    }
}

sub update {
    my ($collection, $query, $object, $options) = @args;
    return unless $collection && $query && $object;
    my $ports = grp_get "jabbot-memory" or return;

    for (@$ports) {
        snd $_, "update" => $collection, $query, $object, $options;
    }
}

1;
