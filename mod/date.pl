#!/usr/local/bin/perl

BEGIN { push @INC, "../lib"; }

use strict;
use Jabbot::Lib;
use Jabbot::ModLib;

$_ = $MSG{body};
my $reply;

my %ZhDay = (
    MON => "星期一",
    TUE => "星期二",
    WED => "星期三",
    THU => "星期四",
    FRI => "星期五",
    SAT => "星期六",
    SUN => "星期日",
    );

if(/^(.*)(?:是)?星期幾/) {
    my $target = $1;
    use Date::Day;
 
    my $p = '(.+)號';
    my $p0 = '(.+)月(.+)號';
    my $p1 = '(.+)年(.+)月(.+)號';
    my @now = localtime(time);
    if ($target =~ /$p1/) {
	my ($o,$m,$n) = ($1,$2,$3);
	trim_whitespace($m,$n,$o);
	my $result = &day($m,$n,$o);
	$reply = $ZhDay{$result};
    } elsif ($target =~ /$p0/) {
	my ($m,$n) = ($1,$2);
	trim_whitespace($m,$n);
	my $result = &day($m,$n,$now[5]+1900);
	$reply = $ZhDay{$result};
    } elsif($target =~ /$p/) {
	my $n = $1;
	trim_whitespace($n);
	my $result = &day($now[4]+1,$n,$now[5]+1900);
	$reply = $ZhDay{$result};
    }
} elsif (/^(上上|下下|這個|上|下|這)星期(..)幾號/) {
} else {
    exit(0);
}

my $priority = 10000 if(length($reply) > 0);

my %rmsg = (
    priority => $priority,
    from     => $BOT_NICK,
    to       => "",
    public   => 1,
    body     => $reply
    );

reply (\%rmsg);

