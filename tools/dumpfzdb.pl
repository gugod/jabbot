#!/usr/bin/perl

use DB_File;

use strict;
use OurNet::FuzzyIndex;

my $idxfile  = $ARGV[0] || die"No given dbfile";;
my $pagesize = undef;      # Page size (twice of an average record)
my $cache    = undef;      # Cache size (undef to use default)
my $subdbs   = 0;          # Number of child dbs; 0 for none

# Initiate the DB from scratch
my $db = OurNet::FuzzyIndex->new($idxfile, $pagesize, $cache, $subdbs);

# [$X =] tie %hash,  'DB_File', $filename, $flags, $mode, $DB_BTREE ;
#my %db;
#my $X= tie %db,'DB_File',$ARGV[0],O_RDWR,0660,$DB_BTREE;
#foreach (keys %db) {
#    if($db{$_} =~ m/:tw\./) {
#	print "$_ => $db{$_}\n";
#	delete $db{$_};
#	$X->del_dup($_,$db{$_});
#    }
#}

#$db->delkey("blahblahblah");

foreach ( $db->getkeys(0) ) {
	print "$_\n";
}

