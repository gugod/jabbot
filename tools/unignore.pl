#!/usr/bin/perl

use DB_File;
use Jabbot::Lib;

tie %ignores, 'DB_File', "${DB_DIR}/ignorenicks.db", O_CREAT|O_RDWR ;

foreach (@ARGV){
	$ignores{$_} = 0;
}

untie %ignores;

