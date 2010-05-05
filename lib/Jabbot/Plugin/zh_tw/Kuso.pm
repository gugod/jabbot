package Jabbot::Plugin::zh_tw::Kuso;
use common::sense;
use Object::Tiny;

sub can_answer { 1 }

sub answer {
    my ($self, $text) = @_;
    my $reply;

    given($text) {
        when("!") {
            $reply = "驚嘆號是棒槌";
        }
        when(/還不賴(!?)/) {
            $reply = ($1?"驚嘆號是棒槌，":"") . "真的還不賴"
        }
        when(/^make\s+me\s?./i) {
            $reply = "WHAT? MAKE IT YOURSELF"
        }
        when(/^sudo\s+make/) {
            $reply = "OKAY"
        }
    }

    return {
        content => $reply,
        confidence => 0.5
    } if $reply;
}

1;
