package Jabbot::FrontEnd::Twitter;
use strict;
use warnings;
use Jabbot::FrontEnd -base;
use Encode qw(encode decode from_to);
use YAML;
use Net::Twitter;

sub process {
    my $self = shift;
    my $config = $self->hub->config;

    my $twit = Net::Twitter->new(
        useranme => $config->{twitter_username},
        password => $config->{twitter_password}
    );


}



1;
