package Jabbot::Plugin::zh_tw::EraConvert;
use v5.36;
use utf8;

use Object::Tiny qw(core);
use Try::Tiny;
use Date::Japanese::Era;

my $RE_japanese_era = qr(明治|大正|昭和|平成|令和);

sub can_answer {
    my ($self, $message) = @_;
    my $text = $message->{body};
    if ($text =~ m/(?:$RE_japanese_era)\s*(?:[0-9]+)\s*年/o) {
        return 1;
    }
    return 0;
}

sub answer {
    my ($self, $message) = @_;

    my @ans;
    while ($message->{body} =~ m/(?<era> $RE_japanese_era)(?<year> [0-9]+)年/gx) {
        my $year = try {
            my $era = Date::Japanese::Era->new($+{era}, $+{year});
            $era->gregorian_year;
        };
        push @ans, [$+{era} . $+{year} . "年", $year];
    }

    my $text = join "", map {
        ($_->[1] ? ($_->[0] . "為西元" . $_->[1] . "年") : ("似乎沒有" . $_->[0])) . "。"
    } @ans;

    return {
        body  => $text,
        score => 1,
    }
}

1;
