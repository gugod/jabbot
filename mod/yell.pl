#!/usr/local/bin/perl

BEGIN { push @INC, "../lib"; }

use strict;
use Jabbot::Lib;
use Jabbot::ModLib;

if (rand(5) > 2) {
#	print STDERR "exit\n";
	exit(0);
}

my $s = $MSG{body};
my $r;

if ($s =~ /讚/ ) {
    $r = "讚！";
} elsif ($s =~ /真(?:正|是)*(.+)(?:[\.\s]|，|。)*$/) {
    $r = rand_choose("$1！","是啊","沒錯","");
} elsif ($s =~ /又(.+)(?:[\.\s]|，|。)*$/) {
    $r = rand_choose("真辛苦","又來囉","苦啊","為什麼又$1?");
} elsif ($s =~ /:\(/) {
    $r = rand_choose("別難過",":-/");
} elsif ($s =~ /:[Pp]/) {
    $r = rand_choose(":p");
} elsif ($s =~ /\.{3,}\s*$/) {
    $r = rand_choose("hmmm...","嗯...");
} elsif ($s =~ /苦/) {
    $r =  rand_choose("加油！");
} elsif ($s =~ /\bping\b/i) {
    $r = rand_choose("pong","PONG","pong pong pong","碰");
}

my $to = $MSG{from};

unless($MSG{to} eq $BOT_NICK) {
    undef $to;
}

reply({
    priority => 0,
    from     => $BOT_NICK ,
    to       => $to,
    body     => $r
    });

