#!/usr/local/bin/perl
use strict;
use warnings;

use lib 'lib';
use Jabbot;
my @configs = qw(config.yaml -plugins plugins);

Jabbot->new->load_hub(@configs)->console->process(@ARGV);

