package Jabbot::Fun;
use v5.36;
use utf8;
use Jabbot::External::TaiwanReservoir;

use Exporter 'import';

our @EXPORT_OK = qw(bag_eq time_next_full_moon next_full_moon_is_tonight hbars_of_top10_reservoir_usage_percentage);

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

sub next_full_moon_is_tonight {
    my $t_now = time;
    my $t_fullmoon = time_next_full_moon();

    my $t1 = Time::Moment->from_epoch($t_now)->at_midnight;
    my $t2 = Time::Moment->from_epoch($t_fullmoon)->at_midnight;

    return $t1 == $t2;
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

my @hbars = ('▁', '▂', '▃', '▄', '▅', '▆', '▇','█');
sub hbar {
    my ($n) = @_;
    return undef unless defined $n;

    my $b = int($n / (int(100 / (@hbars - 1)) + 1));
    $b = $#hbars if $b > $#hbars;
    $b = 0 if $b < 0;
    return $hbars[$b];
}

sub hbars_of_top10_reservoir_usage_percentage {
    my $d = Jabbot::External::TaiwanReservoir->new->usage_percentage;

    my %reservoir_by_name = map { $_->{"ReservoirName"} => $_ } grep { $_->{"ReservoirName"} } values %$d;

    my @top10_south_to_north = qw( 牡丹水庫 南化水庫 烏山頭水庫 曾文水庫 霧社水庫 日月潭水庫 鯉魚潭水庫 德基水庫 石門水庫 翡翠水庫 );

    my @percentages = map { $reservoir_by_name{$_}{"UsagePercentage"} // 0 } @top10_south_to_north;

    return join "", map { hbar(int(100 * $_)) } @percentages;
}

1;
