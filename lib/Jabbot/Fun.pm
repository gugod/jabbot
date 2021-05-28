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

sub hbars_of_reservoir_usage_percentage {
    my $d = Jabbot::External::TaiwanReservoir->new->usage_percentage;

    my %reservoir_by_name = map { $_->{"ReservoirName"} => $_ } grep { $_->{"ReservoirName"} } values %$d;

    # List taken from https://water.taiwanstat.com/
    my @names_north_to_south = qw(新山水庫 翡翠水庫 石門水庫 永和山水庫 寶山水庫 寶山第二水庫 明德水庫 鯉魚潭水庫 德基水庫 石岡壩 日月潭水庫 霧社水庫 湖山水庫 仁義潭水庫 蘭潭水庫 白河水庫 曾文水庫 烏山頭水庫 南化水庫 阿公店水庫 牡丹水庫);

    my @percentages = map { $reservoir_by_name{$_}{"UsagePercentage"} // 0 } reverse @names_north_to_south;

    return join "", map { hbar(int(100 * $_)) } @percentages;
}

1;
