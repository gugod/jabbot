package Jabbot::FrontEnd::MSN;
use strict;
use warnings;
use Jabbot::FrontEnd -base;
use Net::Msmgr;
use Net::Msmgr::Session;
use Net::Msmgr::User;
use Encode qw(encode decode from_to);
use YAML;
my $config;
my $self;

sub process {
    $self= shift;
    $config = $self->config;

    my $session = new Net::Msmgr::Session;
    my $user = new Net::Msmgr::User(user     => $config->{msn_username},
                                    password => $config->{msn_password});
    $session->user($user);
    $session->login_handler(sub {say "I login"});
    $session->connect_handler(sub {say "I connected"});
    $session->disconnect_handler(sub{say "I disconnect"});
    $session->Login;
}

1;
