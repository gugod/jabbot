#!/usr/local/bin/perl

BEGIN { push @INC, "../lib"; }

use strict;
use DB_File;
use Jabbot::Lib;
use Jabbot::ModLib;

my %karmadb;
tie %karmadb, 'DB_File', "${DB_DIR}/karma.db", O_CREAT|O_RDWR ;

my $priority = 0;
my $reply = '';
my $s = $MSG{body};
my $k;
if($s =~ /\S(?:\+\+|\-\-)(?:\s|$)/) {
    $k = getKeyword($s);
    if ( $s =~ m/\+\+/ ) {
	increase($k);
    } elsif ( $s =~ m/\-\-/ ) {
	decrease($k);
    }
    delete $karmadb{$k} if($karmadb{$k} == 0);
} elsif ($s =~ /^karma\s+scoreboard\s*$/i) {
    $reply = join (", ", map
	{ "$_(" . $karmadb{$_} .")" }
	(sort { $karmadb{$b} <=> $karmadb{$a} }
	keys %karmadb)[0..10]);
} elsif ($s =~ /^negative\s+karma\s+scoreboard\s*$/i) {
    $reply = join (", ", map
	{ "$_(" . $karmadb{$_} .")" }
	(sort { $karmadb{$a} <=> $karmadb{$b} }
	keys %karmadb)[0..10]);
} elsif ($s =~ /^karma\s+(.*)\s*$/) {
    my $karma = query($1);
    $reply = ($karma == 0)?"$1 has neutral karma":"$1 has karma of $karma";
}

$priority = 10000 if (length($reply) > 0);

my %rmsg = (
    priority => $priority,
    from     => $BOT_NICK ,
    to       => $MSG{from},
    body     => $reply
    );

delete $karmadb{""};
untie(%karmadb);
reply (\%rmsg);

# __FUNCTIONS__
sub getKeyword {
    my $str = shift;
    $str =~ s/(?:\+\+|--).*$//;
    
    # Quoted by quote, or determined by whitespaces
    if($str =~ /([\'\"])(.*)(\1)$/) {
	$str = $2;
    } else {
	$str = (split(/ /,$str))[-1];
    }
    return $str;
}

sub increase {
    $karmadb{$_[0]}++;
}

sub decrease {
    $karmadb{$_[0]}--;
}

sub query {
    $karmadb{$_[0]};
}
