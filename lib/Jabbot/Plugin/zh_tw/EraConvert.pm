package Jabbot::Plugin::zh_tw::EraConvert;
use v5.18;
use utf8;
use Object::Tiny qw(core);
use Date::Japanese::Era;

sub can_answer {
    my ($self, $message) = @_;
    my $text = $message->{body};
    if ($text =~ m/(明治|大正|昭和|平成|令和)([0-9]+)年/) {
        $self->{__japanese_era} = $1;
        $self->{__japanese_year} = $2;

        return 1;
    }
    return 0;
}

sub answer {
    my ($self, $message) = @_;

    my $text;

    if ($self->{__japanese_era}) {
        my $era = Date::Japanese::Era->new(
            $self->{__japanese_era},
            $self->{__japanese_year}
        );
        my $year = $era->gregorian_year;

        $text = $self->{__japanese_era} . $self->{__japanese_year} . "年為西元" . $year . "年";
    }

    return undef unless defined($text);

    return {
        body  => $text,
        score => 1,
    }
}

1;
