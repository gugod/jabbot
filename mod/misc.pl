#!/usr/local/bin/perl

BEGIN { push @INC, "../lib"; }

use strict;
use DB_File;
use Jabbot::Lib;
use Jabbot::ModLib;
use Encode::Guess;
use Lingua::ZH::Numbers 'big5';

my $s = $MSG{body};
my $reply;
my $priority = 0;
my $to       = $MSG{from};
my $c;
if($s =~ /^date\?*$/i) {
    $reply = `/bin/date`;
} elsif($s =~ /^nslookup\s+([\w\.]+)\?*$/i) {
    $reply = `/usr/bin/host $1`;
    $reply =~ s/\n/ , /gs;
} elsif( $s =~ /^!+$/ ) {
    $c = $s =~ tr/!/!/;
    if( $c == 1 ) {
	$reply = "Åå¹Ä¸¹¬O´Îºl¡C";
    }	
    else {
	$reply = number_to_zh($c) . "®Ú´Îºl¡C";
    }
} elsif($s =~ /^ping\s+([\w\.]+)\?*$/i) {
#    use Net::Ping;
#    my $p = Net::Ping->new();
#    $p->hires();
#    my ($ret, $duration, $ip) = $p->ping($1, 6);
#    if ($ret) {
#	$reply = sprintf("%s is alive. Response time %.2f ms",$1,$duration*1000);
#    } else {
#	$reply = "$1 is dead.";
#    }
#    $p->close();

    if(ping_a_host($1)) {
	$reply = "$1 is alive";
    } else {
	$reply = "$1 is dead";
    }

    sub ping_a_host {
      my $host = shift;
      `ping -i 1 -c 1 $host 2>/dev/null` =~ /0 packets rec/ ? 0 : 1;
    }

} 

$priority = 10000 if(length($reply) > 0);

my %rmsg = (
    priority => $priority,
    from     => $BOT_NICK ,
    to       => $to,
    public   => 1,
    body     => $reply
    );

reply (\%rmsg);
