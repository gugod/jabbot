package Jabbot::Plugin::zh_tw::Polite;
use v5.18;
use utf8;
use Object::Tiny qw(core);

sub can_answer {
    my ($self, $message) = @_;
    my $text = $message->{body};
    if ($text =~ /謝謝/) {
        return 1;
    }
    return 0;
}

sub answer {
    my ($self, $message) = @_;
    return {
        body => "不客氣",
        score => 2 / length($message->{body}),
    };
}

1;
