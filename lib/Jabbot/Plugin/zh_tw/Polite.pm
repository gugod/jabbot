package Jabbot::Plugin::zh_tw::Polite;
use v5.18;
use utf8;
use Object::Tiny qw(core);

sub can_answer {
    my ($self, $text) = @_;
    return $text =~ /謝謝/;
}

sub answer {
    return {
        body => "不客氣",
        score => 1,
    }
}

1;
