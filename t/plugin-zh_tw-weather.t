#!/usr/bin/env perl
use common::sense;
use Test::More;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

use Jabbot::Plugin::zh_tw::Weather;

my @positives = (
    "台北在下雨嗎",
    "台北現在天氣如何",
    "台北天氣預報",
    "新北市天氣預報",
    "新竹會下雨嗎",
    "新竹有下雨嗎",
    "台中是晴天嗎",
    "臺南很冷嗎",
    "高雄會熱嗎",
    "新竹氣象"
);

my @negatives = (
    "油飯好油",
    "原子筆沒水",
    "天氣好熱"
);

my @unknown_location = (
    "竹北會熱嗎",
    "士林有下雨嗎"
);

for (@positives) {
    my $obj = Jabbot::Plugin::zh_tw::Weather->new;

    ok $obj->can_answer($_), $obj->{area} . ", " . $obj->{hint};;
    ok $obj->{area};
    ok $obj->{hint};
}

for (@negatives) {
    my $obj = Jabbot::Plugin::zh_tw::Weather->new;

    ok !$obj->can_answer($_), "Negative: $_";
}

done_testing;
