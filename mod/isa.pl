#!/usr/local/bin/perl

BEGIN { push @INC, "../lib"; }

use strict;
use DB_File;
use Encode qw/decode/;

use Jabbot::Lib;
use Jabbot::ModLib;

my $qstring = $MSG{body};

my %isadb;
tie %isadb, 'DB_File', "${DB_DIR}/isa.db", O_CREAT|O_RDWR ;

my $ymodifiers = "好像|應該|就|乃|只|衹|真的|真";
my $priority = 0;
my $r;

$qstring =~ s/^(.*)是誰\s*(\?|？)$/誰是$1？/;

if ($qstring =~ /^誰是/) {
	$qstring .= "？";
}
if($qstring =~ /(\?|？)$/ ) {
	# Don't reply anything if I'm not been asked.
    	exit(0) unless($MSG{to} eq $BOT_NICK) ;
	$qstring =~ s/(?:\?|？|\s)+$//;
	if($MSG{to} eq $BOT_NICK) {
		$qstring =~ s/你/我/g;
	}
	if ($qstring =~ /^誰是\s*(.*?)\s*$/) {
		$r = _queryWhoIsWhat($qstring);
	} elsif ($qstring =~ /是(?!什麼)/) {
		$r = _queryWhatIsWhat($qstring);
	} elsif ($qstring =~ /是什麼/) {
		$qstring =~ s/\s*是什麼//;
	}
        if(length($isadb{"$qstring"}) > 0) {
		$r = $isadb{"$qstring"};
		$priority = 1000;
	}
} elsif($qstring =~ /^(?:(?:(?:dump|(?:tell me)) all keywords about)|(?:what do you know about))\s+([^\?]+)[\s\?]*$/) {
	my $wanted = quotemeta($1);
	my @iknow = grep { $_ =~ /$wanted/i } keys %isadb;
	if(@iknow) {
	    $r = "一共有 " .( $#iknow + 1) ." 筆: " . join(" || ", @iknow);
	    $r = "一共有 ". ($#iknow + 1) ." 筆, 實在太多了"
		if (length($r) > 400);
	}
	$r ||= "我啥都不知道，別打我";
} elsif($qstring =~ /^(?:dump|(?:tell me)) all about\s+(.*)\s*$/) {
	my $wanted = quotemeta($1);
	my @iknow = grep { $_ =~ /$wanted/i } keys %isadb;
	my $k = scalar(@iknow);
	$k = 3 if $k > 3;
	$r = join("。", map {$isadb{$_}} (sort { rand() <=> rand() } @iknow)[0..$k]);
	$r = "太多了，三天三夜說不完" if (length($r) > 400);
	$r ||= "我啥都不知道，別打我";
} elsif($qstring =~ /^forget all about\s+(.*)\s*$/ && $MSG{to} eq $BOT_NICK) {
	my $wanted = quotemeta($1);
	my $n = 0 ;
	map { $n++; delete $isadb{$_} }
	grep { $_ =~ /$wanted/ }
	keys %isadb;
	$r= ($n == 0)? "並無任何與 $1 有關的資料"
	 : "一共有 $n 筆資料從資料庫中永遠刪除了";
} elsif($qstring =~ /(?:anything\s+about\s+)(.*)\s*(\?!!!+)/ && $MSG{to} eq $BOT_NICK) {
	my $wanted = quotemeta($1);
	$r = rand_choose(map {$isadb{$_}} grep { $_ =~ /$wanted/ } keys %isadb);
} elsif($qstring =~ /^forget\s+(.*)$/  && $MSG{to} eq $BOT_NICK) {
	delete $isadb{$1};
	$r= "ok";
} elsif(length($isadb{"$qstring"}) > 0 && rand(20) > 17) {
	$r= $isadb{"$qstring"};
} else {
	$r = do_my_job($qstring);
}

delete $isadb{''};
untie %isadb;

if(length($r) > 0) {
    $priority += 10000;
}

reply({from => $BOT_NICK,
       to   => $MSG{from},
       priority => $priority,
       body => $r});

sub do_my_job {
	my $what = shift;
	strip_meanless_tsi($what);
	if($MSG{to} eq $BOT_NICK) {
		$what =~ s/你/我/g;
	}
	my @sentances = split(/。/, $what);
	my $r;
	my @rdb =qw(ok 了解 瞭解 原來如此 我知道了 原來如此阿！ 記住了);
	my $TOKEN = '(?:是|很)';
	foreach (@sentances) {
		if (/$TOKEN/) {
			my ($k,$v) = split(/(?:不)?(?:$ymodifiers)?$TOKEN/ , $_, 2);
			$k =~ s/\s+$//;
			$isadb{"$k"} = $_;
			$r = rand_choose(@rdb);
		} elsif (/(.+)\sis\salso\s(.+)/i) {
			my ($k,$v) = ($1,$2);
			$k =~ s/\s+$//;
			if(length($isadb{$k}) > 0) {
			    $isadb{$k} = $v;
			} else {
			    $isadb{$k} .= " or $v";
			}
			$r = rand_choose(@rdb);
		} elsif (/\s[Ii][Ss]\s/) {
			my ($k,$v) = split(/\s[Ii][Ss]\s/ , $_, 2);
			$k =~ s/\s+$//;
			$isadb{$k} = $_;
			$r = rand_choose(@rdb);
		}
	}
	return $r if($MSG{to} eq $BOT_NICK);
}

sub strip_meanless_tsi {
	$_[0] =~ s/^其實(，|,)*//x ;
	$_[0] =~ s/(?:吧|喔)$//x ;
	$_[0];
}

sub _queryWhoIsWhat {
    my $qstring = shift;
    my $r;

    my @fuzzyans;
    my $wanted = $1;
    $wanted =~ s/呢$//;
    if (length($isadb{"$wanted"}) > 0) {
	push @fuzzyans,$wanted;
    }

    $wanted = quotemeta($wanted);
    foreach (keys %isadb) {
	my $realv; $realv = $isadb{"$_"};
	if ( $realv =~ m/$wanted/ ) {
	    push @fuzzyans,$_;
	}
    }
    if(scalar @fuzzyans > 0) {
	my $v = $isadb{rand_choose(@fuzzyans)};
	my $who = undef;
	if ($v =~ /^(.+?)\s*是$wanted$/) {
	    $who = $1;
	}
	if($who) {
	    $r = $who;
	    $priority = 1000;
	} else {
	    $r = "我聽說過: $v";
	}
    } else {
	$r = "我不知道 \@_\@";
    }
    return $r;
}

sub _queryWhatIsWhat {
    my $qstring = shift;
    my $r;
    my ($k,$v) = split(/(?:不)?(?:$ymodifiers)?是/ , $qstring, 2);
    $k =~ s/\s+$//;
    my $realv; $realv = $isadb{"$k"};
    my ($k2,$v2) = split(/(?:不)?(?:$ymodifiers)?是/ , $realv, 2);
    if(length($realv) > 0 && length($v) > 0) {
	if ($qstring eq $realv) {
	    $r = "是啊";	
	} elsif ( $v2 =~ m/$v/ || $v =~ m/$v2/ ) {
	    $r = rand_choose("好像","應該","可能")
		. rand_choose("是","")
		. rand_choose("吧","喔","呢");
	} else {
	    $r = rand_choose("不是","搞錯了")
		. rand_choose("啦","吧?");
	}	
    }
    return $r;
}

