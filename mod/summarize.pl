#!/usr/local/bin/perl

BEGIN { push @INC, "../lib"; }

use strict;
use DB_File;
use Jabbot::Lib;
use Jabbot::ModLib;
use Encode::Guess;
use Lingua::ZH::Numbers 'big5';
use Lingua::ZH::Summarize ;

my $s = $MSG{body};
my $reply;
my $priority = 0;
my $to       = $MSG{from};
my $c;
my $sumlen = 120;
my $public = 1;

## Configurable Variable
my $http_proxy = "http://proxy.ntu.edu.tw:3128/";
####

if($s =~ /^summarize\s+(http:\S+)\s*/ && $MSG{to} eq $BOT_NICK) {
## Contributed by kcwu
	require LWP::UserAgent;
	my $title="";
	my $ua = LWP::UserAgent->new(env_proxy => 1,
			keep_alive => 1,
			timeout => 30,
			);
	$ua->proxy('http',$http_proxy);
	my @urlmatch=(		[
			'www.ettoday.com',
			sub {($title) = ($_[0]=~m/<td height="25"><font size="4" color="#0000ff"><b>([^<]*)<\/b>/im); $_[0]=~m/<font color="#4B4B4B" class="text">(.+)<\/font>/im},
			sub { $_[0] =~ s/<script.+<\/script>//mg ; $_[0]},
			sub { $_[0] =~ s/<[^<]+>//mg ; $_[0]},
			sub { $_[0] =~ s/\n//mg; $_[0] },
			sub { trim_whitespace(@_) ; @_ },
			sub { Lingua::ZH::Summarize::summarize($_[0],maxlength=>$sumlen)},
			sub { "東森新聞報 - [ ".$title." ]： ".$_[0]." " }
#sub { "東森新聞報：[ ".$_[0]." ]" }
			],
			[
			'tw.news.yahoo.com',
			sub { ($title) = ($_[0]=~m/<font color="#0000CC">([^<]*)\s*<\/font>/is); $_[0] =~ m/<big>(.+)<\/big>/is },
			sub { $_[0] =~ s/<script.+<\/script>//mg ; $_[0]},
			sub { $_[0] =~ s/<[^<]+>//mg ; $_[0]},
			sub { $_[0] =~ s/\n//mg; $_[0] },
			sub { trim_whitespace(@_) ; @_ },
			sub { Lingua::ZH::Summarize::summarize($_[0],maxlength=>$sumlen)},
			sub { "Yahoo! 奇摩新聞: [ ".$title." ]： ".$_[0]." " }
			],
			[
		'yam.udn.com',
	sub { ($title) = ($_[0]=~m/<title>([^<]*)<\/title>/im); $_[0] =~ m/<!-- YamTextStart -->(.+)<!-- YamTextEnd -->/is },
	sub { $_[0] =~ s/<script.+<\/script>//mg ; $_[0]},
	sub { $_[0] =~ s/<!--(.*?)-->//sg ; $_[0]},
	sub { $_[0] =~ s/<[^<]+>//mg ; $_[0]},
	sub { $_[0] =~ s/\n//mg; $_[0] },
	sub { $_[0] =~ s/\t//mg; $_[0] },
	sub { trim_whitespace(@_) ; @_ },
	sub { Lingua::ZH::Summarize::summarize($_[0],maxlength=>$sumlen)},
	sub { "[ ".$title." ]: ".$_[0]." " }

	],
	[
		'taiwan.cnet.com' ,
	sub { ($title) = ($_[0]=~m/<title>([^<]*)<\/title>/im); $title = (split(/[:]/,$title))[-1]; $_[0]=~ m/<!-- story body start -->(.+)<!-- story body end -->/is },
	sub { $_[0] =~ s/<script.+<\/script>//mg ; $_[0]},
	sub { $_[0] =~ s/<[^<]+>//mg ; $_[0]},
#sub { $_[0] =~ s/\n//mg; $_[0] },
	sub { trim_whitespace(@_) ; @_ },
	sub { Lingua::ZH::Summarize::summarize($_[0],maxlength=>$sumlen)},
	sub { "CNET：[ ".$title." ]:".$_[0]." " }
	],
	[
		'http://',
#		   sub { ($_[0]=~m/[：:|]/ and (split /[：:|]/,$_[0])[-1]) or () },
	sub { $MSG{from} . ": 本網站尚無摘要功\能。" },
	]
		);

	my $request = HTTP::Request->new('GET', "$1");
	$ua->max_size(40960);
	my $response;
	eval {
		local $SIG{ALRM} = sub { die"timeout\n"};
		alarm 5;
		$response = $ua->request($request);
		alarm 0;
	};
	if($@) {
		die unless $@ eq "timeout\n";
	}
	unless($response->is_success) {
		$reply = "this url is broken"
			if($MSG{to} eq $BOT_NICK);
	} else {
		my @content=();
		eval {
			local $SIG{ALRM} = sub { die"timeout\n"};
			my $real_uri = $response->base;
			foreach (@urlmatch) {
				my $k = @$_[0];
				my @v = @$_[1 .. (@$_-1)];
				next unless($real_uri  =~ /\Q$k/m);
				@content=($response->content);
				foreach(@v) {
					alarm 45;
					@content=$_->(@content);
					alarm 0;
					last unless @content;
				}
				last;
			}
			if(defined $content[0]) {
				$reply=$content[0];
				$to="";
				$reply = any2big5(decode_special($reply));
			}
		};
		if ($@) {
			die unless $@ eq "timeout\n";
			$reply = "對不起，我做不完摘要，換個別的試試。";
		}
	}
}elsif($s =~ /^content\s+(http:\S+)\s*/ && $MSG{to} eq $BOT_NICK) {
## Contributed by kcwu
	require LWP::UserAgent;
	my $title="";
	$public = 0;
	my $ua = LWP::UserAgent->new(env_proxy => 1,
			keep_alive => 1,
			timeout => 30,
			);
	$ua->proxy('http',$http_proxy);
	my @urlmatch=(		[
			'www.ettoday.com',
			sub {($title) = ($_[0]=~m/<td height="25"><font size="4" color="#0000ff"><b>([^<]*)<\/b>/im); $_[0]=~m/<font color="#4B4B4B" class="text">(.+)<\/font>/im},
			sub { $_[0] =~ s/<script.+<\/script>//mg ; $_[0]},
			sub { $_[0] =~ s/<[^<]+>//mg ; $_[0]},
			sub { $_[0] =~ s/\n//mg; $_[0] },
			sub { trim_whitespace(@_) ; @_ },
			sub { "東森新聞報 - [ ".$title." ]： ".$_[0]." " }
#sub { "東森新聞報：[ ".$_[0]." ]" }
			],
			[
			'tw.news.yahoo.com',
			sub { ($title) = ($_[0]=~m/<font color="#0000CC">([^<]*)\s*<\/font>/is); $_[0] =~ m/<big>(.+)<\/big>/is },
			sub { $_[0] =~ s/<script.+<\/script>//mg ; $_[0]},
			sub { $_[0] =~ s/<[^<]+>//mg ; $_[0]},
			sub { $_[0] =~ s/\n//mg; $_[0] },
			sub { trim_whitespace(@_) ; @_ },
			sub { "Yahoo! 奇摩新聞: [ ".$title." ]： ".$_[0]." " }
			],
			[
			'taiwan.cnet.com' ,
			sub { ($title) = ($_[0]=~m/<title>([^<]*)<\/title>/im); $title = (split(/[:]/,$title))[-1]; $_[0]=~ m/<!-- story body start -->(.+)<!-- story body end -->/is },
			sub { $_[0] =~ s/<script.+<\/script>//mg ; $_[0]},
			sub { $_[0] =~ s/<[^<]+>//mg ; $_[0]},
#sub { $_[0] =~ s/\n//mg; $_[0] },
			sub { trim_whitespace(@_) ; @_ },
			sub { "CNET：[ ".$title." ]:".$_[0]." " }
			],
			[
				'yam.udn.com',
			sub { ($title) = ($_[0]=~m/<title>([^<]*)<\/title>/im); $_[0] =~ m/<!-- YamTextStart -->(.+)<!-- YamTextEnd -->/is },
			sub { $_[0] =~ s/<script.+<\/script>//mg ; $_[0]},
			sub { $_[0] =~ s/<!--(.*?)-->//sg ; $_[0]},
			sub { $_[0] =~ s/<[^<]+>//mg ; $_[0]},
			sub { $_[0] =~ s/\n//mg; $_[0] },
			sub { $_[0] =~ s/\t//mg; $_[0] },
			sub { trim_whitespace(@_) ; @_ },
			sub { "[ ".$title." ]: ".$_[0]." " }

			],
			[
				'http://',
#		   sub { ($_[0]=~m/[：:|]/ and (split /[：:|]/,$_[0])[-1]) or () },
			sub { $MSG{from} . ": 本網站尚無摘要功\能。" },
			]
				);

			my $request = HTTP::Request->new('GET', "$1");
			$ua->max_size(40960);
			my $response;
			eval {
				local $SIG{ALRM} = sub { die"timeout\n"};
				if($s =~ /udn/i) {
# $request = HTTP::Request->new('GET', "http://gugod.org/");
#$request = HTTP::Request->new('GET', 'file:///tmp/antiudn');
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
					next unless $response->base =~ /\Q$k/m;
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
					$reply = any2big5(decode_special($reply));
				}
			}
}elsif($s =~ /(http:\S+)\s*/) {
## Contributed by kcwu
	require LWP::UserAgent;
	my $ua = LWP::UserAgent->new(env_proxy => 1,
			keep_alive => 1,
			timeout => 30,
			);
	$ua->proxy('http',$http_proxy);
	my @urlmatch=([
			'udn' ,
#		 sub { "為了對聯合報系的抵制不列出標題" },
			sub { $_[0]=~m/<title>([^<]*)<\/title>/im },
			sub { (split(/ [|] /,$_[0]))[-1] },
			sub { trim_whitespace(@_) ; @_ },
			sub { "聯合新聞網：「".$_[0]."」" }
			],
			[
			'appledaily.com.tw',
			sub { $_[0] =~ m/<SPAN class=ARTTEXTBOLDBIG>(.+?)<\/SPAN>/im},
			sub { $_[0] =~ s/<br>/ /mg; @_ },
			sub { trim_whitespace(@_) ; @_ },
			sub { "蘋果日報：「".$_[0]."」" }
			],
			[
			'tw.news.yahoo.com',
#sub { $_[0]=~m/<title>([^<]*)<\/title>/im },
			sub { $_[0]=~m/<font color="#0000CC">([^<]*)\s*<\/font>/is },
#		   sub { ($_[0]=~m/[：:|]/ and (split /[：:|]/,$_[0])[-1]) or () },
			sub { $_[0] =~ s/\n+/ /gm; @_ },
			sub { "Yahoo! 奇摩新聞: [ " . $_[0] . " ]" }
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
				'www.ettoday.com',
			sub {$_[0]=~m/<td height="25"><font size="4" color="#0000ff"><b>([^<]*)<\/b>/im},
			sub { trim_whitespace(@_) ; @_ },
			sub { "東森新聞報：[ ".$_[0]." ]" }
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
				alarm 5;
				$response = $ua->request($request);
				alarm 0;
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
					next unless $response->base =~ /\Q$k/m;
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
					$reply = any2big5(decode_special($reply));
				}
			}
}

$priority = 10000 if(length($reply) > 0);

my %rmsg = (
		priority => $priority,
		from     => $BOT_NICK ,
		to       => $to,
		public   => $public,
		body     => $reply
	   );

reply (\%rmsg);

sub decode_special {
# Decode special characters
	my $reply = shift;
	$reply =~ s/&#(\d+);/pack('U*', $1)/eg;
	$reply =~ s/&gt;/>/g;
	$reply =~ s/&lt;/</g;
	$reply =~ s/&amp;/&/g;
	return $reply;
}

sub any2big5 {
	my $reply = shift;
	foreach(qw/big5 big5-eten shiftjis gb2312-raw gb12345-raw hz iso-ir-165 cp936 utf8/) {
		my $decoder = guess_encoding($reply, ($_));
		if(ref($decoder)) {
			my $utf8 = $decoder->decode($reply);
			$reply = Encode::encode("big5", $utf8);
			last;
		}
	}
	return $reply;
}
