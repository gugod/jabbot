#!/usr/local/bin/perl

use strict;
use warnings;
our $VERSION = '3.0';

use lib 'lib';
use Jabbot;
my @configs = qw(config.yaml -plugins plugins);

Jabbot->new->load_hub(@configs)->irc->process(@ARGV);

