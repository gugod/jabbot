package Jabbot::TaiwanLotto;
use Jabbot::Plugin -Base;

const class_id => 'taiwanlotto';

sub process {
    my $s = shift->text;
    my $reply;
    if($s =~ /^lotto$/i) {
        $reply = join(",", sort{$a<=>$b}(sort{rand()<=>rand()}(1..42))[0..5]);
    } elsif($s =~ /^\Q四星彩\E$/) {
        warn "Matched [$s]\n";
        my $t = sprintf"%04d",int(rand(10000));
        $reply = sprintf("正彩 %s, 前三彩 %s, 後三彩 %s, 前對彩 %s, 後對彩 %s.",
                         $t, substr($t,0,3), substr($t,-3,3), m/(\d\d)(\d\d)/);
    }
    $self->message->new(text => $reply,
                        priority => (defined $reply)?10000:0);
}
