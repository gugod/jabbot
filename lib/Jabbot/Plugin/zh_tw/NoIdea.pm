package Jabbot::Plugin::zh_tw::NoIdea;
use v5.18;
use utf8;
use Object::Tiny qw(core);

sub can_answer {
    my ($self, $message) = @_;
    my $text = $message->{body};
    if ($text =~ s/\s*[\!\?？！]+\s*\z//) {
        return 0.5;
    }
    return 0;
}

sub answer {
    my ($self, $message) = @_;
    my @res = qw(不知道 不知 不了解 不懂 看不懂);
    my $text = $res[ rand(@res) ];
    return {
        body  => $text,
        score => 0.6,
    }
}

1;
