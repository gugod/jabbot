#!/usr/local/bin/perl

BEGIN { push @INC, "../lib"; }

use strict;
use Jabbot::Lib;
use Jabbot::ModLib;

my %hytv_channels = (
		     HBO => 'hbo1',
		     STAR => 'star5',
		     AXN => 'tvbs5',
		     CINEMAX => 'cinemax1',
		     '好萊塢電影台' => 'cbs2',
		     '東森洋片台' => 'cd1',
		     '龍祥電影台' => 'ls1',
		     '緯來電影台' => 'fsw2',
		     '衛視電影台' => 'star4',
		    );

my $s = $MSG{body};
my $reply;
my $priority = 0;
my $to       = $MSG{from};

if ( $s =~ /^movies?([\s\?]|？)*$/i ) {
    eval {
        $SIG{ALRM} = sub { die "alarm\n"; };
	alarm(30);
        $reply = get_hytv_movie();
	alarm(0);
    };
    if($@) {
	die "Connection Timeout";
    }elsif (length($reply) > 0) {
	$priority = 100000;
    }
} elsif($s =~ /^movie\s+channels?([\s\?]|？)*$/i) {
    $reply = join (", ", keys %hytv_channels);
} elsif ( $s =~ /^movie\s+(?:on\s+)?(.*?)([\s\?]|？)*$/i ) {
    my $channel = $1;
    my $moviedata = get_hytv_movie("$channel");
    if (length($moviedata) > 0) {
	$priority = 100000;
	$reply = "$moviedata"
    }
}

my %rmsg = (
    priority => $priority,
    from     => $BOT_NICK,
    to       => "",
    public   => 1,
    body     => $reply
    );

reply (\%rmsg);


sub get_hytv_movie {
    my ($CH, $date, $start, $end) =@_;
    my @now = localtime(time);
    my @channels;
    if ($start eq "") { 
	@now = localtime(time-3600);
	$start = sprintf("%02d00",($now[2] eq 0 ? 1 : $now[2])); 
    }
    if ($end eq "") {
	$end = sprintf("%02d00",($now[2]+4)>24 ? 24 : ($now[2]+4));
    }
    if ($date eq "") {
	$date = sprintf("%d%02d%02d",$now[5]+1900,$now[4]+1,$now[3]);
    }
    if ($CH eq "") {
	push (@channels, values(%hytv_channels)) ;
    } else {
	my @c1 = split(/,|[Aa][Nn][Dd]|&/,$CH);
        trim_whitespace(@c1);
        my @unknown;
	foreach my $c (@c1) {
	    foreach (keys %hytv_channels) {
		if(/\Q$c\E/i) {
		    push @channels, $hytv_channels{$_};
		}
	    }
	}
        unless(@channels) {
	    return "Unknown channel(s)";
	}
    };
    use HTTP::Request::Common qw(POST);
    use LWP::UserAgent;
    my $ua = LWP::UserAgent->new(timeout => 30) or die $!;
    my %params = ();
    $params{'search_option'} = '1';
    $params{'page'} = '1';
    $params{'start'} = $start;
    $params{'end'} = $end;
    $params{'DATE'} = $date;
    push (@{$params{'CH'}}, @channels) ;
    $params{'search'}='%7D%B6%6C%A9%64%AC%DF%B8';
#    use Data::Dumper;
#    print STDERR Dumper \%params;
    my $res = $ua->request(
			   POST 'http://www.hytv.com.tw/cgi/tvsearch.cgi',
			   \%params
			  );
    if ($res->is_success) {
	my $moviedata = $res->content;
	$moviedata =~ s/<script[^>]*>.*?<\/script.*?>//igs;
	$moviedata =~ s/<\/td>\n/<\/td>/igs;
	$moviedata =~ s/<[^>]*>//igs;
	$moviedata =~ s/ +/ /igs;
	$moviedata =~ s/ +\n +/\n/igs;
	$moviedata =~ s/\n+/\n/igs;
	$moviedata =~ s/HyTV.+\n//ig;
	$moviedata =~ s/節目關鍵字查詢.+//igs;
	trim_whitespace($moviedata);
	return $moviedata;
    }
    return;
}

