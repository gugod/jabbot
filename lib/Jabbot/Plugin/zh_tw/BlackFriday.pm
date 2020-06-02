package Jabbot::Plugin::zh_tw::BlackFriday;
use v5.18;
use utf8;
use Object::Tiny qw(core);
use Time::Moment;

sub can_answer {
    my ($self, $message) = @_;
    if ($message->{body} =~ m/ ((?<year>[0-9]+)\s*年)? (十三號|黑色) 星期五 /x) {
        if ($+{year}) {
            $self->{query}{year} = $+{year};
        }
        return 1;
    }

    return 0;
}

sub answer {
    my $self = shift;
    my $query = $self->{query};
    return $self->answer_year($query->{year}) if $query->{year};
    return $self->answer_next();
}

sub answer_year {
    my ($self, $year) = @_;
    my $tm = Time::Moment->new( year => $year, month => 1, day => 13 );

    my @dates;
    while ($tm->year == $year) {
        if ($tm->day_of_week == 5) {
            push @dates, $tm;
        }
        $tm = $tm->plus_months(1);
    }

    my $ans = join "、", map { $_->month . ' 月 ' . $_->day_of_month . ' 日' } @dates;
    return {
        score => 1,
        body => $ans,
    }
}

sub answer_next {
    my ($self, $year) = @_;
    my $tm = Time::Moment->now;

    $tm = $tm->plus_months(1) if $tm->day_of_month > 13;
    $tm = $tm->with_day_of_month(13);

    while ($tm->day_of_week != 5) {
        $tm = $tm->plus_months(1);
    }

    my $ans = '下一次十三號星期五是： ' . $tm->year . ' 年 ' . $tm->month . ' 月 ' . $tm->day_of_month . ' 日';
    return {
        score => 1,
        body => $ans,
    }
}

1;
