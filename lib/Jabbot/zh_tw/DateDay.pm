package Jabbot::zh_tw::DateDay;
use Jabbot::Plugin -Base;
use Date::Day;
use utf8;

const class_id => 'zhtw_dateday';

my %ZhDay = (
    MON => "星期一",
    TUE => "星期二",
    WED => "星期三",
    THU => "星期四",
    FRI => "星期五",
    SAT => "星期六",
    SUN => "星期日",
    );

sub process {
    my $msg = shift->text;
    my $reply;
    if($msg =~ /^(.*號)(?:是)?(?:星期幾)?/) {
        my $target = $1;
        my $p = '(.+)號';
        my $p0 = '(.+)月(.+)號';
        my $p1 = '(.+)年(.+)月(.+)號';
        my @now = localtime(time);
        if ($target =~ /$p1/) {
            my ($o,$m,$n) = ($1,$2,$3);
            $self->trim($m,$n,$o);
            my $result = &day($m,$n,$o);
            $reply = $ZhDay{$result};
        } elsif ($target =~ /$p0/) {
            my ($m,$n) = ($1,$2);
            $self->trim($m,$n);
            my $result = &day($m,$n,$now[5]+1900);
            $reply = $ZhDay{$result};
        } elsif($target =~ /$p/) {
            my $n = $1;
            $self->trim($n);
            my $result = &day($now[4]+1,$n,$now[5]+1900);
            $reply = $ZhDay{$result};
        }
        $reply = "${target}是${reply}"
            if(defined $reply && rand(100) > 60);
    }
    $self->reply($reply,10000);
}
