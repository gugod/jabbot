package Jabbot::Plugin::zh_tw::Kuso;
use v5.18;
use utf8;
use Object::Tiny qw(core);

sub can_answer {
    my ($self, $message) = @_;
    my $text = $message->{body};
    my $ratio = length($text =~ s/\P{Han}//r)/length($text);
    return $ratio > 0.5 ? 1 : 0;
}

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
        elsif(/^幫我(\p{Han})/) {
            $reply = "不要，你自己$1";
        }
        elsif(/^請幫我/) {
            $reply = "好喔";
        }
    }

    return {
        body => $reply,
        score => 1
    } if $reply;
}

1;
