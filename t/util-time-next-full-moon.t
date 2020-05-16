#!/usr/bin/env perl

use Test2::V0;

use Jabbot::Util qw(time_next_full_moon);


my $now = time;

for (0..31) {
    my $epoch = $now + $_ * 86400;
    my $time_fullmoon = time_next_full_moon( $epoch );

    ok $time_fullmoon > $epoch;
}

done_testing;
