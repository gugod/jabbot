package Jabbot::Plugin::zh_tw::Polite;
use v5.36;
use utf8;
use Object::Tiny qw(core);

sub can_answer ($self, $message) {
    my $text = $message->{body};
    if ($text =~ /謝謝/) {
        return 1;
    }
    return 0;
}

sub answer ($self, $message) {
    return {
        body => "不客氣",
        score => 2 / length($message->{body}),
    };
}

1;
