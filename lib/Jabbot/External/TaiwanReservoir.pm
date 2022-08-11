package Jabbot::External::TaiwanReservoir;
use v5.36;

use JSON;
use Object::Tiny;
use Mojo::UserAgent;

sub basic {
    # 水庫每日營運狀況 https://data.gov.tw/dataset/41568
    my $ua = Mojo::UserAgent->new;
    my $res = $ua->insecure(1)->get('https://data.wra.gov.tw/Service/OpenData.aspx?format=json&id=50C8256D-30C5-4B8D-9B84-2E14D5C6DF71')->result;
    die "Failed to retrieve the daily operational statistics." if $res->is_error;

    my $rows = $res->json->{"DailyOperationalStatisticsOfReservoirs_OPENDATA"};
    my %d = map { $_->{"ReservoirIdentifier"} => $_ } @$rows;
    return \%d;
}

sub current {
    # 水庫水情資料 https://data.gov.tw/dataset/45501
    my $ua = Mojo::UserAgent->new;
    my $res = $ua->insecure(1)->get('https://data.wra.gov.tw/Service/OpenData.aspx?format=json&id=1602CA19-B224-4CC3-AA31-11B1B124530F')->result;
    die "Failed to retrieve the condition data" if $res->is_error;

    my $rows = $res->json->{"ReservoirConditionData_OPENDATA"};
    my %d = map { $_->{"ReservoirIdentifier"} => $_ } @$rows;
    return \%d;
}

sub usage_percentage {
    my $d1 = current();
    my $d2 = basic();

    my $json = JSON->new->pretty->canonical;
    my $d3 = {};
    for my $id (keys %$d1) {
        my $d = $d3->{$id} = {};
        $d->{$_} = $d2->{$id}{$_} for qw(ReservoirIdentifier ReservoirName EffectiveCapacity RecordTime);
        $d->{$_} = $d1->{$id}{$_} for qw(EffectiveWaterStorageCapacity ObservationTime);

        if ( $d->{"EffectiveCapacity"} && $d->{"EffectiveWaterStorageCapacity"}) {
            $d->{"UsagePercentage"} = $d->{"EffectiveWaterStorageCapacity"} / $d->{"EffectiveCapacity"};
        }
    }

    return $d3;
}

1;
