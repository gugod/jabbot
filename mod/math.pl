#!/usr/local/bin/perl

BEGIN { push @INC, "../lib"; }

use strict;

use Jabbot::Lib;
use Jabbot::ModLib;

my $priority = 0;
local $_ = $MSG{body};
my $r;

if(/^solve_quadratic_root\(([\d\.\-]+)\s*,\s*([\d\.\-]+)\s*,\s*([\d\.\-]+)\)\s*$/) {
  use IPC::Open2;
  my $pid = open2(\*RDRFH, \*WTRFH, "/usr/bin/bc -l ${DB_DIR}/math.bc");
  print WTRFH "quadratic_condition_eq($1, $2, $3)\n";
  my $ans0 = <RDRFH>;
  chomp($ans0);
  if($ans0 < 0) {
    $r = "無實數解"
  } else {
    print WTRFH "quadratic_root_p($1,$2,$3)\n";
    my $ans1 = <RDRFH>;
    chomp($ans1);
    print WTRFH "quadratic_root_n($1,$2,$3)\n";
    my $ans2 = <RDRFH>;
    chomp($ans2);
    $r = "X = $ans1 or $ans2";
  }
  close(BC);
} elsif(/^[-+*\/^()\d\s\.]*$/) {
    use Safe;
    my $comp = new Safe;
    $comp->permit_only(qw(:base_core :base_math));
    $SIG{ALRM} = sub { die "timeout" };
    alarm(1);
    $r = $comp->reval($_);
    alarm(0);
    if ($@ && $@ =~ m/timeout/) { $r = "Timeout!" }
    undef $r unless $r ne $_;
}

$priority =1000 if(defined $r);

reply({ from => $BOT_NICK,
	to   => $MSG{to},
	body => $r,
	priority => $priority
    });


