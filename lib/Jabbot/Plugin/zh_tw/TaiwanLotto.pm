package Jabbot::Plugin::zh_tw::TaiwanLotto;
use common::sense;
use Object::Tiny;

sub can_answer {
    my ($self, $text) = @_;
    ($self->{matched}) = $text =~ /^(樂透|四星彩)$/;
}

sub answer {
    my $self = shift;

    my $reply;
    given($self->{matched}) {
        when("樂透") {
            $reply = join(",", sort{$a<=>$b}(sort{rand()<=>rand()}(1..42))[0..5]);
        }
        when("四星彩") {
            $_ = sprintf"%04d",int(rand(10000));
            $reply = sprintf("正彩 %s, 前三彩 %s, 後三彩 %s, 前對彩 %s, 後對彩 %s.", $_, substr($_,0,3), substr($_,-3,3), m/(\d\d)(\d\d)/);
        }
    }

    return {
        content => $reply,
        confidence => 1
    }
}
