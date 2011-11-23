package Jabbot::Back::Twitter;
use warnings;
use strict;
use parent qw(Jabbot::Back);

sub run {
    configure profile => "jabbot-twitter";
    my $config             = Jabbot->config->{twitter};

    AE::cv->recv;
}


1;
