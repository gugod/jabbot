#!/usr/local/bin/perl

BEGIN { push @INC, "../lib"; }

use strict;
use Jabbot::Lib;
use Jabbot::ModLib;

qq{美金(USD) 新台幣(NTD) 日圓(JPY) 港幣(HKD) 人民幣(MCY) 英鎊(GRP) 歐洲通貨(ECU) 加拿大元(CAD) 澳元(AUD) 泰銖(THB) 新加坡元(SGD) 南韓圜(KOW) 印尼盾(IDR) 馬來西亞幣(MYR) 菲律賓披索(PHP) 印度盧比(INR) 阿幣(SAR) 科威特幣(KWD) 挪威幣(NOK) 瑞士法郎(SWF) 瑞典克朗(SEK) 丹麥克朗(DMK) 巴西幣(BRC) 墨西哥披索(MEP) 阿根廷披索(ARS) 智利披索(CLP) 委瑞內拉幣(VEB) 南非幣(ZAR) 俄羅斯盧布(RUR) 紐西蘭元(NZD)  };

my %cname = (USD => "美金", NTD => "新台幣", JPY => "日圓", HKD => "港幣",
	     MCY => "人民幣", GRP => "英鎊", ECU => "歐洲通貨", CAD => "加拿大元",
	     AUD => "澳元", THB => "泰銖", SGD => "新加坡元", KOW => "南韓圜",
	     IDR => "印尼盾", MYR => "馬來西亞幣", PHP => "菲律賓披索",
	     INR => "印度盧比", SAR => "阿幣", KWD => "科威特幣", NOK => "挪威幣",
	     SWF => "瑞士法郎", SEK => "瑞典克朗", DMK => "丹麥克朗", BRC => "巴西幣",
	     MEP => "墨西哥披索", ARS => "阿根廷披索", CLP => "智利披索",
	     VEB => "委瑞內拉幣", ZAR => "南非幣", RUR => "俄羅斯盧布",
	     NZD => "紐西蘭元" );

my %coin = (
   USD => "1", NTD => "2", JPY => "3", HKD => "4", MCY => "5",
   GRP => "6", ECU => "7", CAD => "8", AUD => "9", THB => "10",
   SGD => "11", KOW => "12", IDR => "13", MYR => "14", PHP => "15",
   INR => "16", SAR => "17", KWD => "18", NOK => "19", SWF => "20",
   SEK => "21", DMK => "22", BRC => "23", MEP => "24", ARS => "25",
   CLP => "26", VEB => "27", ZAR => "28", RUR => "29", NZD => "30"
);

my %calias = ( EUR => "ECU", "RMB" => "MCY", "YEN" => "JPY", "CHF" =>"SWF"
	      );

my $s = $MSG{body};
my $reply;
my $priority = 0;
my $to       = $MSG{from};
my $allsymbol = join("|",keys %coin) . "|" . join("|",keys %calias);
my $qmark = '(?:[\s\?]|？)*';
if ( $s =~ /^([\d\.]+)\s*($allsymbol)\s+to\s+($allsymbol)$qmark$/i ) {
    $reply = get_ex_money($1,$2,$3);
} elsif ( $s =~ /^([\d\.]+)\s*($allsymbol)$qmark$/i ) {
    $reply = get_ex_money($1,$2);
} elsif ( $s =~ /^currency\s+list([\s\?])*?/i ) {
    $reply = "You may ask my to exchange these currency: "
	. join(",", map { $cname{$_}."($_)" } sort keys %cname );
} elsif ( $s =~ /^help (currency|money|exchang)/) {
    $reply =
	'I can do currency exchanging, Example: 10 USD to NTD? , or simply "10 USD"' .
	"\n" .
	'To list all currency, say "currency list" to me';
}

$priority = 10000 if(length($reply) > 0);

my %rmsg = (
    priority => $priority,
    from     => $BOT_NICK,
    to       => $to,
    public   => 1,
    body     => $reply
    );

reply (\%rmsg);

sub get_ex_money {
#     my ($data) =@_;
#     $data =~ s/ //;
#     my @datas = split(/,/,$data);
#     my ($from,$to,$money);
#     if ( $#datas == 2 ) {
#         $from = $datas[0];
#         $to = $datas[1];
#         $money = $datas[2];
#     } elsif ($#datas == 1) {
#         $from = "2"; #default NTD
#         $to = $datas[0];
#         $money = $datas[1];
#     } else {
#         return "usage: money FROM,TO,MONEY";
#    };

    my ($money,$from,$to) = @_;
    $to ||= "NTD"; # Default to NTD
    $from = expand_alias(uc($from));
    $to   = expand_alias(uc($to));
    # Random answer :-/
    while($from eq $to) {
	$to = rand_choose(keys %coin);
    }
    use HTTP::Request::Common qw(GET);
    use LWP::UserAgent;
    my $ua = LWP::UserAgent->new(timeout => 300) or die $!;;
    my $res;
    eval {
        $SIG{ALRM} = sub { die "alarm\n"; };
	alarm(30);
	$res = $ua->request(
		GET 'http://tw.stock.yahoo.com/d/c/ex.php?money='.$money.
		'&select1='.$coin{$from}.'&select2='.$coin{$to}
		);
	alarm(0);
    };
    if($@) {
	die "Connection Timeout";
    }

    if ($res->is_success) {
	my $data = $res->content;
	if ($data =~ /經過計算後，([^<]+)/) {
	    my $reStr = $1;
	    $reStr =~ s/&nbsp;/ /igs;
	    $reStr =~ s/  / /igs;
	    return $reStr;
	} else {
	    return "找不到";
	};
    }
}

sub expand_alias {
    my $from = shift;
    if(length($calias{$from}) > 0) {
	$from = $calias{$from};
    }
    return $from;
}
