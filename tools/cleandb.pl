#!/usr/bin/perl

use DB_File;

my %db; tie %db,'DB_File',$ARGV[0];

my $k = $ARGV[0] || die "Needs a key";
delete $db{"$k"};

