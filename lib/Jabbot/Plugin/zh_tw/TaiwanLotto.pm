package Jabbot::Plugin::zh_tw::TaiwanLotto;
use v5.18;
use utf8;
use Object::Tiny qw(core);

sub can_answer {
    my ($self,$text) = @_;
    ($self->{matched}) = $text =~ /^(樂透|四星彩)$/;
}

sub answer {
    my ($self,$text) = @_;
    my $reply;
    
    if ($self->{matched} eq "樂透") {
        $reply = join(",", sort{$a<=>$b}(sort{rand()<=>rand()}(1..42))[0..5]);
    } elsif($self->{matched} eq "四星彩") {
        $_ = sprintf"%04d",int(rand(10000));
        $reply = sprintf("正彩 %s, 前三彩 %s, 後三彩 %s, 前對彩 %s, 後對彩 %s.", $_, substr($_,0,3), substr($_,-3,3), m/(\d\d)(\d\d)/);
    }

    return {
        body => $reply,
        score => 1
    }
}

1;
