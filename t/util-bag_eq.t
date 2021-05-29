#!/usr/bin/env perl

use Test2::V0;

use Jabbot::Fun qw(bag_eq);

ok bag_eq(["a", "b", "c"], ["c", "a", "b"]);
ok ! bag_eq(["a", "b", "c"], ["c", "a", "b", "c"]);

ok bag_eq(["1", "2", "03"], ["1", "03", "2"]);
ok ! bag_eq(["1", "2", "03"], ["1", "2", "3"]);


done_testing;
