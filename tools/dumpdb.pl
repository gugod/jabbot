#!/usr/bin/perl

use DB_File;

my %db; tie %db,'DB_File',$ARGV[0],O_RDONLY;

foreach (keys %db) {
	print "$_ => $db{$_}\n";
}

