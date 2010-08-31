package Jabbot::Plugin::zh_tw::Kuso;
use Jabbot::Plugin;

sub can_answer { 1 }

sub answer {
    my ($text) = @args;

    my $reply;

    my $confidence = 0.5;

    given($text) {
        when("!") {
            $reply = "驚嘆號是棒槌";
        }
        when(/還不賴/) {
            $self->{habiulai_count} ||= 0;
            $self->{habiulai_count} +=  1;

            if ($self->{habiulai_count} > 1 + 4 * rand) {
                $reply = "還不賴！";
                $confidence = 1;
                $self->{habiulai_count} = 0;
            }
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
        confidence => $confidence
    } if $reply;
}

1;
