#!/usr/local/bin/perl

BEGIN { push @INC, "../lib"; }

use strict;
use Jabbot::Lib;
use Jabbot::ModLib;

my $s = $MSG{body};
my $reply;
my $priority = 0;
my $to       = $MSG{from};

if ( $s =~ /^song\s+(?:(?:on|of|about)\s+)?(.*?)([\s\?]|¡H)*$/i ) {
    eval {
        $SIG{ALRM} = sub { die "alarm\n"; };
	alarm(30);
	$reply = get_so61_song("$1");
	alarm(0);
    };
    if($@) {
	die "Connection Timeout";
    }elsif (length($reply) > 0) {
	$priority = 100000;
    }
}

if(length($reply) > 0) {
    use Lingua::ZH::Wrap qw(wrap);
    $priority = 10000;
    $Lingua::ZH::Wrap::columns  = 110;             # Change columns
    $Lingua::ZH::Wrap::overflow = 1;
    my @lines = ($reply);
    $reply = wrap( '', '', @lines );
}

my %rmsg = (
    priority => $priority,
    from     => $BOT_NICK ,
    to       => $to,
    public   => 1,
    body     => $reply
    );

reply (\%rmsg);

sub get_so61_song {
    my ($data) =@_;
    my @datas = split(/,/,$data);
    my ($singer,$title);
    if ( $#datas > 0 ) {
	$title = $datas[1];
	$singer = $datas[0];
    } else {
	$title = $datas[0];
    };
    use HTTP::Request::Common qw(POST);
    use LWP::UserAgent;
    my $ua = LWP::UserAgent->new(timeout => 30) or die $!;
    my %params = ();
    $params{'singer'} = $singer;
    $params{'singerStr'} = '1';
    $params{'album'} = '';
    $params{'albumStr'} = '1';
    $params{'title'} = $title;
    $params{'titleStr'} = '1';
    my $res = $ua->request(
			   POST 'http://so61.com/bin/cgi/find.pl',
			   \%params);
    if ($res->is_success) {
	my $sonedata = $res->content;
	if ($sonedata =~ /<pre>([^<]+)/) {
	    my $return_value = $1;
	    $return_value =~ s/\n/ /g;
	    return $return_value;
	} elsif ($sonedata =~ /<textarea[^>]+>([^<]+)/) {
	    my $return_value = $1;
	    $return_value =~ s/¡¹.+//g;
	    $return_value =~ s/\n/ /g;
	    return $return_value;
	} else {
	    return "§ä¤£¨ì";
	};
    }
    return;
}
