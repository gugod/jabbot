#!/usr/local/bin/perl

BEGIN { push @INC, "../lib"; }

use strict;
use Jabbot::Lib;
use Jabbot::ModLib;
use Jabbot::Lib qw(rand_choose);

exit if rand(5) >  1;

my $r =  rand_choose("Have a nice day","Bad day?", "Happy?") . "\n";

reply({
    priority => 0,
    from => $BOT_NICK,
    to   => '', 
    body => $r
    });

