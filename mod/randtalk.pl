#!/usr/local/bin/perl

BEGIN {
	push @INC, "../";
}

use Jabbot::Lib qw(rand_choose);

print rand_choose("Have a nice day","go to hell", "lonjump haven") . "\n";

