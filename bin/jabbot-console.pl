#!/usr/bin/perl
# 	$Id: jabbot.pl,v 1.9 2002/06/16 14:20:03 gugod Exp $

use strict;
use lib qw/.. ./;
use IO::Handle;
use Time::localtime;
use DB_File;
use IPC::Open2;
use File::Glob ':glob';
use POSIX ":sys_wait_h";
use Term::ReadLine;

use Jabbot::Lib;

$|++;
local $/;

my $DEBUG = 0;

# Setup bot's module.
chdir(${MOD_DIR});
my @bot_module = bsd_glob("*.pl");
chdir("-");

if($DEBUG) {
    use Data::Dumper;
    print Dumper \@bot_module;
}

my $term = new Term::ReadLine 'Jabbot-Console';
my $OUT = $term->OUT || \*STDOUT;
while ( defined ($_ = $term->readline('jabbot> ')) ) {
    my $str = $_;
    last if ($str =~ /^quit$/i);
    my $to = strip_leading_nick($str);
    my %msg = (
	from  => $ENV{USER} || 'somebody@console',
	to    => $to || 'jabbot2',
	body  => $str
    );
    my @r = sort { $b->{priority} cmp $a->{priority} }
    grep { length($_->{body}) > 0 }
    map {
	my $pid = open2(\*RDRFH, \*WTRFH, "${MOD_DIR}/$_");
	print WTRFH msg2txt(\%msg);
	close(WTRFH);
	undef $/;
	my $r1 = <RDRFH>;
	my %rmsg = txt2msg($r1);
	close(RDRFH);
	wait();
	\%rmsg;
    } @bot_module ;

    my $reply;
    if ($r[0]->{priority} == 0 ) {
	$reply = $r[int(rand($#r))]->{body};
    } else {
	$reply =  $r[0]->{body};
    }
    print $OUT "$reply \n";
}

