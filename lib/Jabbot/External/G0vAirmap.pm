use v5.18;

package Jabbot::External::G0vAirmap {
    use Object::Tiny;
    use constant URL_FEED => 'https://api.airmap.g0v.tw/json/airmap.json';

    use Geo::Hash;
    use Mojo::UserAgent;

    sub sites {
        my ($self) = @_;
        my $ua = Mojo::UserAgent->new();
        my $res = $ua->get(URL_FEED)->result;
        return $res->json;
    }

    sub sites_grouped_by_geohash4 {
        my ($self) = @_;
        my %sites;
        my $hasher = Geo::Hash->new;
        for my $site (@{ $self->sites }) {
            my $geohash = $hasher->encode(
                $site->{"LatLng"}{"lat"},
                $site->{"LatLng"}{"lng"},
                4,
            );
            push @{ $sites{$geohash} //= [] }, $site;
        }
        return \%sites;
    }
};

1;

__END__

The body of airmap.json is an ArrayRef[HashRef] that looks like this:

[
    {
        "uniqueKey": "ESP32_553F74",
        "SiteName": "ESP32_553F74",
        "SiteGroup": "LASS",
        "Maker": "LASS",
        "LatLng": {
            "lat": 24.791150000000002,
            "lng": 121.79458
        },
        "Data": {
            "Dust2_5": 28,
            "Humidity": 80.81,
            "Temperature": 30.64,
            "Create_at": "2021-06-28T21:35:04Z"
        },
        "Analysis": {
            "ranking": 0,
            "status": null
        },
        "Geometry": {
            "TOWNID": "G04",
            "TOWNCODE": "10002060",
            "COUNTYNAME": "\u5b9c\u862d\u7e23",
            "TOWNNAME": "\u58ef\u570d\u9109",
            "TOWNENG": "Zhuangwei Township",
            "COUNTYID": "G",
            "COUNTYCODE": "10002"
        }
    }
]
