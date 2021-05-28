package Jabbot::Fun;
use v5.26;
use warnings;
use utf8;
use Jabbot::External::TaiwanReservoir;

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
