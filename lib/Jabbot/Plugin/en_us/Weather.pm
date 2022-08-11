package Jabbot::Plugin::en_us::Weather;
use v5.36;
use Object::Tiny qw(core);
use Weather::Underground;

sub can_answer {
    my ($self, $message) = @_;
    my $text = $message->{body};

    if ($text =~ /\A \s* weather \s+ in \s+ ([\p{Letter}, ]+) \s* \?+ \z/ix) {
        $self->{area} = $1;
        return 1;
    }

    return 0;
}

sub answer {
    my ($self, $message) = @_;
    my $text = $message->{body};

    my $weather = Weather::Underground->new(
        place => $self->{area},
        debug => 0,
    ) || die "Error, could not create new weather object: $@\n";

    my $res = { body => "", score => 0 };
    if (my $res_weather = $weather->get_weather()) {
        $res_weather = $res_weather->[0];
        my $res_body = sprintf(
            "%s is %s, %d \x{2103}, Humidity: %.1f%%",
            $res_weather->{place},
            $res_weather->{conditions},
            $res_weather->{temperature_celsius},
            $res_weather->{humidity}
        );
        $res->{body} = $res_body;
        $res->{score} = 1;
    } else {
        $res->{body} = "The weather for " . $self->{area} . " is unknown.";
        $res->{score} = 1;
    }
    return $res;
}

1;
