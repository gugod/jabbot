#!/usr/bin/perl

BEGIN { push @INC, "../lib"; }

use strict;
use Jabbot::Lib;
use Jabbot::ModLib;

use Chatbot::Eliza;

my $mybot = new Chatbot::Eliza;
my $use_memory;
my $string = $MSG{body};
my $r;

if($string =~ /^[\s\w[:punct:]]+$/ &&
	$MSG{to} eq $BOT_NICK) {
	$r = $mybot->transform( $string, $use_memory );
} 

reply({
    from => $BOT_NICK,
    to   => $MSG{to},
    body => $r
    });

