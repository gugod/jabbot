#!/usr/local/bin/perl

BEGIN { push @INC, "../lib"; }

use strict;
use Jabbot::Lib;
use Jabbot::ModLib;

my $s = $MSG{body};
my $reply;
if($s =~ /^lotto$/i) {
  $reply = join(",", sort{$a<=>$b}(sort{rand()<=>rand()}(1..42))[0..5]);
} elsif($s =~ /^\Q四星彩\E$/) {
  print STDERR "Matched [$s]\n";
  $_ = sprintf"%04d",int(rand(10000));
  $reply = sprintf("正彩 %s, 前三彩 %s, 後三彩 %s, 前對彩 %s, 後對彩 %s.",
	  $_, substr($_,0,3), substr($_,-3,3), m/(\d\d)(\d\d)/);
}

exit(0) unless(length($reply) > 0);

reply({
    priority => 10000,
    from     => $BOT_NICK ,
    to       => $MSG{from},
    body     => $reply
    });

