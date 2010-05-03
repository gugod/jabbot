package Jabbot::RemoteCore;
use common::sense;

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub post {
    my ($self, $channel, $text) = @_;
    say STDERR "----\nPOST $channel\n$text";
    return $self;
}

1;
