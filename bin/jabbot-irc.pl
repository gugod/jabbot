#!/usr/local/bin/perl
use strict;
use warnings;
use lib 'lib';
use Jabbot;
my @configs = qw(config.yaml -plugins plugins);

my $j = Jabbot->new;
$j->load_hub(@configs);
$j->hub->config->{frontend_class} = 'Jabbot::FrontEnd::IRC';
$j->hub->frontend->process(@ARGV);

