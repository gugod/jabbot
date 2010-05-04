package Jabbot::Plugin::zh_tw::Polite;
use common::sense;
use Object::Tiny;

sub can_answer {
    my ($self, $text) = @_;
    if ($text =~ m/謝謝/) {
        return 1;
    }
    return 0;
}

sub answer {
    my ($self, undef) = @_;

    return {
        content    => "不客氣",
        confidence => 0.5
    }
}

1;
