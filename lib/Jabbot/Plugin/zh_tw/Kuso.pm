package Jabbot::Plugin::zh_tw::Kuso;
use v5.18;
use utf8;
use Object::Tiny qw(core);

sub can_answer { 1 }

sub answer {
    my ($self, $message) = @_;
    my $text = $message->{body};

    my $reply;

    for($text) {
        if($_ eq "!") {
            $reply = "驚嘆號是棒槌";
        }
        elsif(/好男人|nice *man/) {
            $self->{niceman_count} ||= 0;
            $self->{niceman_count} += 1;

            if ($self->{niceman_count} > 10 * rand) {
                $reply = "不做嗎？";
                $self->{niceman_count} = 0;
            }
        }
        elsif(/還不賴/) {
            $self->{habiulai_count} ||= 0;
            $self->{habiulai_count} +=  1;

            if ($self->{habiulai_count} > 1 + 4 * rand) {
                $reply = "還不賴！";
                $self->{habiulai_count} = 0;
            }
        }
        elsif(/^make\s+me\s?./i) {
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
