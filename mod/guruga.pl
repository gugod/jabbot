#!/usr/bin/perl

BEGIN { push @INC, "../lib"; }

use strict;
use Jabbot::Lib;
use Jabbot::ModLib;

use lib qw/./;
use IO::Handle;
use OurNet::ChatBot;

my $r;
my $s = $MSG{body};
if($MSG{to} eq $BOT_NICK) {
    my $agentname = 'guruga';
    my $chatdb = "${DB_DIR}/${agentname}.db";
    my $chatbot = new OurNet::ChatBot($agentname,$chatdb,0);
    $r = $chatbot->input($s);
    #$r = "chatbot says[$r]";
}

reply({
	priority => 0,
    from    => $BOT_NICK ,
    to      => $MSG{from},
    body    => $r
    });


