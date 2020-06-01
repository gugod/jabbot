package Jabbot::Plugin::zh_tw::Elizaish;
use v5.18;
use utf8;
use Object::Tiny qw(core);
use Ref::Util qw( is_arrayref );

my @RULES = (
    [ qr/ 看了(?<moovie_name>.+) /x,
      '好看嗎？' ],
    [ qr/ 讀了(?<book_name>.+) /x,
      '好看嗎？' ],
    [ qr/ 吃了(?<food_name>.+) /x,
      '好吃嗎？' ],
    [ qr/ 喝了(?<drink_name>.+) /x,
      '好喝嗎？' ],
    [ qr/ 好[看吃喝玩](！|\z) /x,
      '太好了呢' ],
    [ qr/ 不難[看吃喝玩](！|。|\z) /x,
      '不錯喔' ],
    # Generic
    [qr/./x,
     ['嗯嗯', '喔喔']]
);

sub can_answer {
    my ($self, $message) = @_;

    my $body = $message->{body};
    for my $rule (@RULES) {
        my $re = $rule->[0];
        if (my @matched = $body =~ m/($re)/) {
            $self->{__matched} = \@matched;
            $self->{__rule} = $rule;
            return 1;
        }
    }
    return 0;
}

sub answer {
    my ($self, $message) = @_;
    my ($res) = $self->{__rule}->[1];

    if ( is_arrayref($res) ) {
        $res = $res->[rand( 0+ @$res )]
    }

    return {
        body  => $res,
        score => 0.8 * ( length($self->{__matched}[0]) / length($message->{body})) ,
    }
}

1;
