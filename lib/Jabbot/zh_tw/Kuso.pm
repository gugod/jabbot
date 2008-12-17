package Jabbot::zh_tw::Kuso;
use Jabbot::Plugin -Base;
use utf8;

const class_id => 'zh_tw_kuso';

sub process {
    my $msg = shift;
    my $text = $msg->text;

    if ($text eq '!') {
        return $self->reply("驚嘆號是棒槌", 1);
    }

    if ($msg->me) {
        return $self->reply("WHAT? MAKE IT YOURSELF", 1)
            if $text =~ /^make\s+me\s+./i;
        return $self->reply("OKAY", 1)
            if $text =~ /^sudo\s+make\s+me\s+./i;
    }
}


