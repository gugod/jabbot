#!/usr/local/bin/perl
use strict;
use warnings;
use lib 'lib';
use Jabbot;

my $j = Jabbot->new;
$j->load_hub(qw(config.yaml -plugins plugins));
$j->hub->config->{interface_class} = 'Jabbot::FeedReport';
$j->hub->interface->process(@ARGV);
