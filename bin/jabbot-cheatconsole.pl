#!/usr/local/bin/perl
use strict;
use warnings;
use lib 'lib';
use Jabbot;

my $j = Jabbot->new;
$j->load_hub(qw(config.yaml -plugins plugins));
$j->hub->config->{backend_class} = 'Jabbot::BackEnd::CheatConsole';
$j->hub->backend->process(@ARGV);

