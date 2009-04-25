#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Jabbot;
my @configs = qw(config.yaml -plugins plugins);

my $j = Jabbot->new;
$j->load_hub(@configs);
$j->hub->config->{backend_class} = 'Jabbot::BackEnd::Github';
$j->hub->backend->process(@ARGV);

