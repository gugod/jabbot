#!/usr/local/bin/perl

BEGIN { push @INC, "../lib"; }

use strict;
use DB_File;

use Jabbot::Lib;
use Jabbot::ModLib;

use Encode qw(encode decode from_to);

my $priority = 0;

my $qstring = $MSG{body};

exit if ($qstring =~ /你|妳|我|他|她/);

my @db;
my $X = tie @db, 'DB_File', "${DB_DIR}/bowlidx.db",
    O_CREAT|O_RDWR ,0666, $DB_RECNO;

$qstring =~ s/我(?!們)/$MSG{from}/g;
$qstring =~ s/你(?!們)/$MSG{to}/g if (length($MSG{to}) > 0);
if($qstring =~ /(\?|？)\s*$/ && $MSG{to} eq $BOT_NICK) {
    $qstring =~ s/\s*(\?|？)+\s*$//;
    my $reply = rand_choose(map { s/\s*${BOT_NICK}\s*/我/ig; $_ }
			    grep /\Q$qstring\E/ , @db );

    $reply =~ s/\b?\Q$MSG{from}\E\b/你/g;
    $reply =~ s/${BOT_NICK}/我/g;

    $reply =~ s/^\Q$qstring\E// ;

    reply({
	from => $BOT_NICK,
	to   => $MSG{from},
	body => $reply,
	priority => 10,
	});
} else {
    $X->push($qstring) unless(grep /^\Q${qstring}\E$/,@db);
}

if($X->length > 5000) {
#	@db = $db[0..999];
    shift @db;
}

untie @db;

