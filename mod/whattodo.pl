#!/usr/local/bin/perl

BEGIN { push @INC, "../lib"; }

use strict;
use DB_File;
use Jabbot::Lib;
use Jabbot::ModLib;


my $probability = 0;
my $s = $MSG{body};
my ($reply,$hit);
my $priority = 0;
my @cofe = ("Expresso", "Expresso Light",
	      "Expresso Con Panna", "Expresso Macchiato",
	      "Cappuccino", "Caffe Latte", "Short Latte",
	      "Caffe Latte Macchiato", "Caffe Mochaccino",
	      "Caffe Mocha", "Baileys Cappuccino",
	      "Kahlua Cappuccino", "Ice Expresso Light",
	      "Cozy Ice Coffee", "Ice Cappuccino",
	      "Ice Caffe Latte", "Ice Caffe Latte Macchiato",
	      "Ice Caffe Mocha", "Ice Expresso with ice cream",
	      "Ice cream coffee",
	);

my @nowtime = localtime(time);
my $gametime = 0;
if($nowtime[2] > 12) {
    $gametime = 1;
}

my %cozygame;
tie %cozygame, 'DB_File', "${DB_DIR}/cozygame.db", O_CREAT|O_RDWR ;
my $nowdate = "$nowtime[3] $nowtime[4] $nowtime[5]";
my $nowmd = ($nowtime[4] + 1)  ."/$nowtime[3]";
my $nowhm = "$nowtime[2]:$nowtime[1]:$nowtime[0]";

unless ( $cozygame{"__date__"} eq $nowdate ) {
    foreach(keys %cozygame) {
	$cozygame{$_} = 0;
    }
    $cozygame{"__date__"} = $nowdate;
}

$cozygame{lc($MSG{from})} ||= 0;

# If you are not talking to me, I ignore you.
exit(0) unless($MSG{to} eq $BOT_NICK);

$probability = get_prob();
my $maxgametime = 1;
if($s =~ /^((?:今天|要)*喝(?:什麼)?
           |(?:what\sto\sdrink(?:\stoday)?)
           )(\?|？)*/x) {
    $reply = rand_choose(@cofe);
    if($probability > 0 ) {
	$hit = 1 if ( (rand(100) < 100 * $probability));
	if($cozygame{lc($MSG{from})} < $maxgametime 
		&& $gametime
	  ) {
	    $cozygame{lc($MSG{from})}++;
#		$hit=1 if($MSG{from} eq "james_");
	    if($hit) {
		$reply .= " *中獎了* 可以免費使用 Cozy 網路一次";
	    } else {
		$reply .= " (沒中獎) ";
	    }
	    $reply .= "   (中獎機率為 $probability )" if ($probability > 0);
	    $reply .= "，你今天玩了 ". $cozygame{lc($MSG{from})} ." 次"
		if($cozygame{lc($MSG{from})} > 1);
	}
    }
    open(FH,">> ${DB_DIR}/cozygame_record.txt");
    print FH "$nowhm $nowmd , ". lc($MSG{from}) . ", ${reply}\n";
    close(FH);
} elsif($s =~ /^((?:今天)?中獎機率(?:多少)?(?:[\s\?]|？)+)$/) {
    if($probability < 0 ) {
        $reply = "中獎機率有誤, henyi.org down";
    } else {
	$reply = "今天中獎機率是 $probability";
	if($gametime) {
	    $reply .= " (現在可以玩) ";
	} else {
	    $reply .= " (現在不能玩) ";
	}
	$reply .= "，你今天玩了 ". $cozygame{lc($MSG{from})} ." 次";
	$reply .= "See also: 「Cozy 遊戲規則」";
    }
} elsif($s =~ /^(?:
	    (?:cozy\s*rules)|
	    (?:[Cc][Oo][Zz][Yy]\s*遊戲規則))
	(?:[\s\?]|？)+$/x) {
    $reply = "在 Cozy 營業時間(13:00-24:00)內，且 james 在店裡時，"
	."問我「今天喝什麼」則有一次中獎機會（機率由 james 訂），" 
	."若被告知中獎，則可以免費使用網路一次。(不再提供抽獎咖啡)"
	."See also: 「今天中獎機率」";
} else {
  exit(0);
}
$priority = 10000;
my $to = $MSG{from};

# print STDERR "[whattodo] ($priority) $reply \n";

my %rmsg = (
    priority => $priority,
    from     => $BOT_NICK ,
    to       => $to,
    body     => $reply
    );

reply (\%rmsg);

untie %cozygame;

sub get_prob {
    use Net::Ping;

    my $prob = -1;
    my $p = Net::Ping->new();
    $p->hires();
    my ($ret, $duration, $ip) = $p->ping("henyi.org", 6);
    if ($ret) {
	require LWP::UserAgent;
	my $ua = LWP::UserAgent->new(timeout => 5);
	my $response;

# Timeout mechnism
	eval {
	    $SIG{ALRM} = sub { die"alarm\n"; };
	    alarm(10);
	    $response = $ua->get('http://henyi.org/~james/cozy.txt');
	    alarm(0);
	};
	if($@) {
	    die unless $@ eq "alarm\n";
	}

	if ($response->is_success) {
	    $prob = $response->content;
	    trim_whitespace($prob);
	} else {
	    exit(0);
	}
    }
    $p->close();

    return $prob;
}
