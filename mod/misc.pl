#!/usr/local/bin/perl

BEGIN { push @INC, "../lib"; }

use strict;
use DB_File;
use Jabbot::Lib;
use Jabbot::ModLib;
use Encode::Guess;

my $s = $MSG{body};
my $reply;
my $priority = 0;
my $to       = $MSG{from};
if($s =~ /^date\?*$/i) {
    $reply = `/bin/date`;
} elsif($s =~ /^nslookup\s+([\w\.]+)\?*$/i) {
    $reply = `/usr/bin/host $1`;
    $reply =~ s/\n/ , /gs;
} elsif($s =~ /^ping\s+([\w\.]+)\?*$/i) {
    use Net::Ping;

    my $p = Net::Ping->new();
    $p->hires();
    my ($ret, $duration, $ip) = $p->ping($1, 6);
    if ($ret) {
	$reply = sprintf("%s is alive. Response time %.2f ms",$1,$duration*1000);
    } else {
	$reply = "$1 is dead.";
    }
    $p->close();
} elsif($s =~ /(http:\S+)\s/) {
## Contributed by kcwu
  require LWP::UserAgent;
  my $ua = LWP::UserAgent->new(env_proxy => 1,
			       keep_alive => 1,
			       timeout => 30,
			      );
  my @urlmatch=([
		 'udn' ,
#		 sub { "為了對聯合報系的抵制不列出標題" },
		 sub { $_[0]=~m/<title>([^<]*)<\/title>/im },
		 sub { (split(/ [|] /,$_[0]))[-1] },
		 sub { trim_whitespace(@_) ; @_ },
		 sub { "聯合新聞網：「".$_[0]."」" }
		],
		[
		 'www.theregister.co.uk' ,
		 sub { $_[0] =~ m/<div class="storyhead">(.+?)<\/div>/im ;},
		 sub { "The Register: [ ".$_[0]." ]" }
		],
		[
		 'tw.comic.yahoo.com/od/play' ,
		 sub { $_[0]=~m#>([^<>]*?)</font></b></td>#im },
		 sub { "奇摩卡漫：[ ".$_[0]." ]" }
		],
		[
		 'taiwan.cnet.com' ,
		 sub { $_[0]=~m/<title>([^<]*)<\/title>/im },
		 sub { (split(/[:]/,$_[0]))[-1] },
		 sub { trim_whitespace(@_) ; @_ },
		 sub { "CNET：[ ".$_[0]." ]" }
		],
		[
		 'bid.yahoo.com' ,
		 sub { $_[0]=~m/<font size="4"><b>([^<]*)<\/b>/im },
		 sub { trim_whitespace(@_) ; @_ },
		 sub { "Yahoo 拍賣：[ ".$_[0]." ]" }
		],

		[
		 'slashdot.org/',
		 sub { $_[0]=~m/<title>([^<]*)<\/title>/im },
		 sub { (split/[|]/,$_[0])[-1] },
		 sub { trim_whitespace(@_) ; @_ },
		 sub { "Slashdot: [".$_[0]."]" },
		],
		[
		'news.chinatimes.com',
		 sub { $_[0]=~m/<!--title begin-->\s*(.*?)\s*<!--title end-->/m },
		 sub { trim_whitespace(@_) ; @_ },
		 sub { "中時新聞網：「".$_[0]."」" }
#		   sub { $req=HTTP::Request->new('GET', "http://news.chinatimes.com".$_[0]);
#			 $res=$ua->request($req);
#			 "中時新聞網：「".$res->content."」" ;}
		  ],
		[
		'ejokeimg.pchome.com.tw',
		sub { "" },
		],
		  [
		  'http://',
		   sub { $_[0]=~m/<title>([^<]*)<\/title>/im },
#		   sub { ($_[0]=~m/[：:|]/ and (split /[：:|]/,$_[0])[-1]) or () },
		   sub { $_[0] =~ s/\n+/ /gm; @_ },
		   sub { $MSG{from} . "'s URL: [ " . $_[0] . " ]" },
		]
	       );
  
  my $request = HTTP::Request->new('GET', "$1");
  $ua->max_size(40960);
  my $response;
  eval {
    local $SIG{ALRM} = sub { die"timeout\n"};
    if($s =~ /udn/i) {
#        $request = HTTP::Request->new('GET', "http://gugod.org/");
        $request = HTTP::Request->new('GET', 'file:///tmp/antiudn');
	alarm 5;
	$response = $ua->request($request);
	alarm 0;
    } else {
	alarm 5;
	$response = $ua->request($request);
	alarm 0;
    }
  };
  if($@) {
     die unless $@ eq "timeout\n";
  }
  unless($response->is_success) {
    if($MSG{to} eq $BOT_NICK) {
      $reply = "this url is broken";
    }
  } else {
    my @content=();
    foreach (@urlmatch) {
      my $k = @$_[0];
      my @v = @$_[1 .. (@$_-1)];
      next unless $s =~ /\Q$k/m;
      @content=($response->content);
      foreach(@v) {
	@content=$_->(@content);
	last unless @content;
      }
      last;
    }
    if(defined $content[0]) {
      $reply=$content[0];
      $to="";

      # Decode special characters 
      $reply =~ s/&#(\d+);/pack('U*', $1)/eg;
      $reply =~ s/&gt;/>/g;
      $reply =~ s/&lt;/</g;
      $reply =~ s/&amp;/&/g;

      foreach(qw/big5 big5-eten shiftjis gb2312-raw gb12345-raw hz iso-ir-165 cp936 utf8/) {
        my $decoder = guess_encoding($reply, ($_));
        if(ref($decoder)) {
	  my $utf8 = $decoder->decode($reply);
	  $reply = Encode::encode("big5", $utf8);
          last;
        }
      }

    }
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
