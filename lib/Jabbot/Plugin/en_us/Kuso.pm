package Jabbot::Plugin::en_us::Kuso;
use v5.36;
use utf8;
use Object::Tiny qw(core);

sub can_answer {
    my ($self, $message) = @_;
    my $text = $message->{body};
    my $ratio = length($text =~ s/\P{Latin}//r)/length($text);
    return $ratio > 0.5 ? 1 : 0;
}

sub answer {
    my ($self, $message) = @_;
    my $text = $message->{body};

    my $reply;

    for($text) {
        if(/^make\s+me\s?./i) {
            $reply = "WHAT? MAKE IT YOURSELF"
        }
        elsif(/^sudo\s+make/) {
            $reply = "OKAY"
        }
    }

    return {
        body => $reply,
        score => 1
    } if $reply;
}

1;
