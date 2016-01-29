package Jabbot::Plugin::zh_tw::Weather;
use v5.18;
use utf8;
use Object::Tiny qw(core);
use YAML;
use Weather::Google;

sub can_answer {
    my ($self, $text) = @_;

    if ($text =~ /^\s*(.+)\s*天氣[?？]?\s*$/) {
        $self->{area} = $1;
        $self->{hint} = "天氣";
        return 1;
    }

    ($self->{area}) = $text =~ m/((?:南投|嘉義|基隆|宜蘭|屏東|彰化|新北|新竹|桃園|澎湖|臺中|臺北|臺南|臺東|台中|台北|台南|台東|花蓮|苗栗|連江|金門|雲林|高雄)(?:縣|市)?)/;
    ($self->{hint}) = $text =~ m/(weather|冷|暖|寒|暑|熱|涼|雨|晴|天氣|氣象)/;
    ($self->{forcast}) = $text =~ m/([明後]天|預報)/;

    if ( $self->{area} && $self->{hint} ) {
        return 0.5;
    }
    return 0;
}

sub answer {
    my ($self, $text) = @_;

    my $weather = Weather::Google->new($self->{area}, { language => 'zh-TW' });
    my $current = $weather->current_conditions;

    my $reply;

    if ($self->{forcast}) {
        $reply = "";
        my $days = $weather->forecast_conditions;
        foreach my $day (@$days) {
            $reply .= $day->{day_of_week} . ": " . $day->{condition} . ", " . $day->{low} . " ~ " . $day->{high} . " ℃。" ;
        }
    }
    elsif ($current->{condition}) {
        $reply = join(
            ", ",
            "$self->{area} 現在 $current->{condition}",
            "氣溫 $current->{temp_c} ℃",
            $current->{humidity},
            $current->{wind_condition}
        );
    }

    $reply ||= "不知道...";

    return { body => $reply, score => 1 };
}


1;
