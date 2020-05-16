package Jabbot::Util;
use v5.18;
use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(time_next_full_moon);

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

1;

