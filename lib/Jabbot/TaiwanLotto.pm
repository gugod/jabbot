package Jabbot::TaiwanLotto;
use Jabbot::Plugin -Base;
use utf8;

const class_id => 'taiwanlotto';

sub process {
    my $s = shift->text;
    my $reply;
    if($s =~ /^lotto$/i) {
        $reply = join(",", sort{$a<=>$b}(sort{rand()<=>rand()}(1..42))[0..5]);
    } elsif($s =~ /^\Q四星彩\E$/) {
        warn "Matched [$s]\n";
        $_ = sprintf"%04d",int(rand(10000));
        $reply = sprintf("正彩 %s, 前三彩 %s, 後三彩 %s, 前對彩 %s, 後對彩 %s.",
                         $_, substr($_,0,3), substr($_,-3,3), m/(\d\d)(\d\d)/);
    }
    $self->reply($reply,1);
}
