#!/usr/local/bin/perl

BEGIN { push @INC, "../lib"; }

use strict;
use OurNet::FuzzyIndex;
use Jabbot::Lib;
use Jabbot::ModLib;

my $idxfile  = "${DB_DIR}/fzidx.idx"; # Name of the database file
my $pagesize = undef;      # Page size (twice of an average record)
my $cache    = undef;      # Cache size (undef to use default)
my $subdbs   = 0;          # Number of child dbs; 0 for none

# Initiate the DB from scratch
my $db = OurNet::FuzzyIndex->new($idxfile, $pagesize, $cache, $subdbs);


$_ = $MSG{body};
my $priority;
my $r;
# exit(0) unless($MSG{to} eq $BOT_NICK);

if(/^(.+?)=>(.+)$/) {
    my($key,$val) = ($1,$2);
    trim_whitespace($key,$val);
    $db->insert($val,$key);
}elsif(/^°O©¹(?:,|¡A)(.+)$/ || /^remember[,.]\s+(.+)$/ ) {
    my $val = $1;
    trim_whitespace($val);
    $db->insert($val,$val);
}elsif(/^(.+)(?:[?\s]|¡H)?$/ && $MSG{to} eq $BOT_NICK) {
    ($r,$priority) = getQueryResult($1);
} else {
    exit(0);
}

# print STDERR "[fzidx] ($priority) $r \n";

reply({
    priority => $priority,
    from     => $BOT_NICK ,
    to       => $MSG{from},
    body     => $r
    });


sub getQueryResult {
    my $q = shift;
    trim_whitespace($q);
    my %result = $db->query($q);
    my $val;
    foreach my $idx (sort {$result{$b} <=> $result{$a}} keys(%result)) {
	$val = $result{$idx};
	$r .= $db->getkey($idx);
	last;
    }
    return ($r,$val);
}

