#!/usr/local/bin/perl

BEGIN { push @INC, "../lib"; }

use strict;
use Jabbot::Lib;
use Jabbot::ModLib;
use Jabbot::Lib qw(rand_choose);

my $s = $MSG{body};
my $r;
my $to = $MSG{from};

exit unless($MSG{to} eq $BOT_NICK );

if ($s =~ /謝謝/ ) {
    $r = "不客氣";
} elsif ($s =~ /^請.+$/ ) {
    $r = "那就不客氣了~~";
}

reply({
    priority => 10,
    from => $BOT_NICK,
    to   => $to, 
    body => $r
    });

