#!/usr/local/bin/perl

BEGIN { push @INC, "../lib"; }

use strict;
use Jabbot::Lib;
use Jabbot::ModLib;

my $s = $MSG{body};
my $reply;
my $priority = 0;
my $to       = $MSG{from};

if ( $s =~ /^baseball([\s\?]|？)*$/i ) {
    eval {
        $SIG{ALRM} = sub { die "alarm\n"; };
	alarm(30);
	$reply = get_contest_time();
	alarm(0);
    };
    if($@) {
	die "Connection Timeout";
    }elsif (length($reply) > 0) {
	$priority = 100000;
    }
}

my %rmsg = (
    priority => $priority,
    from     => $BOT_NICK ,
    to       => $to,
    public   => 1,
    body     => $reply
    );

reply (\%rmsg);


sub get_contest_time {
    use HTTP::Request::Common qw(GET);
    use LWP::UserAgent;
    use HTML::TableExtract;
    my $ua = LWP::UserAgent->new(timeout => 300) or die $!;;
    my $res = $ua->request(
	GET 'http://www.cpbl.com.tw/Schedule/scoreqry.asp?Show=1',
	);
    if ($res->is_success) {
	return get_table($res->content);
    } else {
	return "NULL";#$res->as_string;
    };
}

sub get_table {
    my ($html_string) = @_;
    my $te = new HTML::TableExtract( depth => 2, subtables => 3); 
    $te->parse($html_string);
    # Examine all matching tables
    my @contests;
    my @data;
    foreach my $ts ($te->table_states()) {
      if ($ts->depth() eq "2") {
	 foreach my $row ($ts->rows) {
	     my $thisrow = join(',', @$row);
	     $thisrow =~ s/\s+//igs;
	     $thisrow =~ s/日期：(.*)/$1/;
	     push @data,$thisrow;
	 }
      }
      foreach my $row ($ts->rows) {
	 my $thisrow = join(',', @$row);
	 $thisrow =~ s/\s+//igs;
         if ($thisrow =~ m/^\d+,/) { # suppose be digit first
	    push @contests, $thisrow. ",". $ts->count();
	 };
      }
    }
    my $results;
    foreach my $contest (@contests) {
       my @rows = split(/,/,$contest);
       my $result;
       $result .= $data[$rows[12]]. " ";
       $result .= "客:".$rows[1] ." ";
       $result .= "主:".$rows[3] ." ";
       if ($rows[2] eq "未賽") {
	   $result .= "時間:".$rows[5] ." ";
       } else {
	   $result .= "比數:".$rows[2] ." ";
	   $result .= "勝投:".$rows[7] ." ";
	   $result .= "敗投:".$rows[8] ." ";
	   if ($rows[9] ne "") {
	       $result .= "救援勝:".$rows[9] ." ";
	   }
	   $result .= "MVP:".$rows[10] ." ";
       }
       $results .= $result."\n";
    };
    return $results;
}
