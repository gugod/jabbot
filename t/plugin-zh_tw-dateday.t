#!/usr/bin/env perl
use v5.36;
use Test2::V0;

use Jabbot::Plugin::zh_tw::DateDay;

my @positives = (
    "2022年4月1日是星期幾",
    "4月1日是星期幾",
    "4號是星期幾",
    "4號星期幾",
);

my @negatives = (
    "油飯好油",
    "原子筆沒水",
);

for my $message (@positives) {
    my $obj = Jabbot::Plugin::zh_tw::DateDay->new;

    ok $obj->can_answer({ body => $message }), "Positive: $message";
    my $ans = $obj->answer({ body => $message });
    is $ans, hash {
        field "body" => D();
        field "score" => D();
    }, $ans->{body} // 'ERR';
}

for my $message (@negatives) {
    my $obj = Jabbot::Plugin::zh_tw::DateDay->new;

    ok !$obj->can_answer({ body => $message }), "Negative: $message";
}

done_testing;
