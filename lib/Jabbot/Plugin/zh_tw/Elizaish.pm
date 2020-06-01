package Jabbot::Plugin::zh_tw::Elizaish;
use v5.18;
use utf8;
use Object::Tiny qw(core);

my @RULES = (
    [ qr/ 吃了(?<food_name>.+) /x,
      '好吃嗎？' ],
    [ qr/ 喝了(?<drink_name>.+) /x,
      '好喝嗎？' ],
    [ qr/ 好[吃喝玩]！ /x,
      '太好了呢' ],
);

sub can_answer {
    my ($self, $message) = @_;

    my $body = $message->{body};
    for my $rule (@RULES) {
        if (my @matched = $body =~ $rule->[0]) {
            $self->{__matched} = \@matched;
            $self->{__rule} = $rule;
            return 1;
        }
    }
    return 0;
}

sub answer {
    my ($self, $message) = @_;
    return {
        body  => $self->{__rule}->[1],
        score => 0.8,
    }
}

1;
