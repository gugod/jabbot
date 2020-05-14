package Jabbot::Plugin::zh_tw::WhatTimeIsIt;
use v5.18;
use utf8;
use Object::Tiny qw(core);

use Time::Moment;

my %tzoffset = (
    洛杉磯 => -480,
    溫哥華 => -480,
    提華納 => -480,
    鳳凰城 => -420,
    舊金山 => -420,
    墨西哥 => -360,
    紐約 => -300,
    多倫多 => -300,
    聖地牙哥 => -240,
    聖保羅 => -180,
    布宜諾斯艾利斯 => -180,
    阿根廷 => -180,
    英國 => 0,
    倫敦 => 0,
    柏林 => 60,
    羅馬 => 60,
    巴黎 => 60,
    馬德里 => 60,
    華沙 => 60,
    羅馬 => 60,
    阿姆斯特丹 => 60,
    開羅 => 120,
    約翰尼斯堡 => 120,
    基輔 => 120,
    布加勒斯特 => 120,
    雅典 => 120,
    耶路撒冷 => 120,
    索菲亞 => 120,
    莫斯科 => 180,
    伊斯坦堡 => 180,
    德黑蘭 => 210,
    杜拜 => 240,
    孟買 => 330,
    加德滿都 => 345,
    雅加達 => 420,
    胡志明市 => 420,
    曼谷 => 420,
    台北 => 480,
    台灣 => 480, ##
    福岡 => 540,
    東京 => 540,
    日本 => 540, ##
    首爾 => 540,
    平壤 => 540,
    雪梨 => 600,
    奧克蘭 => 660,
    紐西蘭 => 660, ##
);

my $re_known_location = '(?:' . join("|", map { "\Q$_\E"} keys %tzoffset) . ')';

sub can_answer {
    my ($self, $message) = @_;
    my $text = $message->{body};

    if ($text =~ /幾點/) {
        return 1;
    }

    return 0;
}

sub answer {
    my ($self, $message) = @_;
    my $text = $message->{body};

    my $reply;
    my $query;
    my $simple = 0;

    my $suffix = qr{(?: 幾點了? | 時間 ) 嗎?\s*[\?？]? }x;
    if ($text =~ m/ $suffix \z/xo) {
        if ($text =~ m/ ($re_known_location) /xo) {
            $query = $1;
        } else {
            $text =~ s/ $suffix \z//x;
            $text =~ s/(你知道|幫我|[查看]+一下|那裡|現在)+//g;

            if ($text) {
                $query = $text;
            } else {
                $query = "台灣";
                $simple = 1;
            }
        }
    }

    return unless defined($query);

    my $offset = $tzoffset{$query};

    unless (defined($offset)) {
        return {
            body  => "我不知道${query}那裡幾點",
            score => 1,
        }
    }

    my $tm_local = Time::Moment->now;
    my $tm_there = $tm_local->with_offset_same_instant($offset);

    if ($tm_local->day_of_month == $tm_there->day_of_month) {
        $reply = ($simple ? "":"${query}現在是 ") . $tm_there->hour . " 點 " . $tm_there->minute . " 分";
    } else {
        my $ymd = $tm_there->year . " 年 " . $tm_there->month . " 月 " . $tm_there->day_of_month . " 日";
        $reply = ($simple ? "": "${query}現在是 ") . $ymd . " " . $tm_there->hour . " 點 " . $tm_there->minute . "分";
    }

    return $reply && {
        body => $reply,
        score => 1
    };
}
1;
