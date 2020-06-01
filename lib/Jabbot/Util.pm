package Jabbot::Util;
use v5.18;
use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(bag_eq time_next_full_moon);

use Astro::MoonPhase qw(phasehunt);

=head3 time_next_full_moon

Usage:

    my $tm1 = time_next_full_moon();
    my $tm2 = time_next_full_moon( $t );

This subroutine calculate the time when next full moon happens and
returns that time as a epoch value.

The one optional argument C<$t> is an epoch value, which is
default to be "now". The return value should be within the future 30
days relative to C<$t>

=cut

sub time_next_full_moon {
    my ($time) = @_;
    $time //= time();

    my @phases = phasehunt($time);
    if ($phases[2] < $time) {
        @phases = phasehunt($phases[4]+1);
    }

    return $phases[2];
}

=head3 bag_eq()

Usage:

    my $bool = bag_eq(\@a1, \@a2);

This subroutine test if the content of C<@a1> and C<@a2> are the same.

=cut

sub bag_eq {
    my ($a1, $a2) = @_;
    return 0 unless @$a1 == @$a2;

    my (%bag1, %bag2);
    $bag1{$_}++ for @$a1;
    $bag2{$_}++ for @$a2;

    for (@$a1) {
        (defined($bag2{$_}) && $bag1{$_} == $bag2{$_}) or return 0;
    }

    for (@$a2) {
        (defined($bag1{$_}) && $bag1{$_} == $bag2{$_}) or return 0;
    }

    return 1;
}


1;

