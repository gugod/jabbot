#!/usr/local/bin/perl

BEGIN {push @INC, "../lib";}

use strict;
use DB_File;
use Encode;
use Jabbot::ModLib;


my $priority = 1000;
my $qstring = $MSG{body}; 

my @zhi = split "",$qstring;

my %db;
tie %db, 'DB_File', "${DB_DIR}/bowcounttsi.db", O_CREAT|O_RDWR;

for my $i (0..$#zhi) {
    for my $j (0..$#zhi-$i) {
	my $tsi = '';
	for my $k (0..$i) {$tsi .= $zhi[$j+$k];}
#	print "  =>". Encode::encode( big5 => $tsi) . "\n";
	$db{"$tsi"} += 1;
    }
}

untie %db;
