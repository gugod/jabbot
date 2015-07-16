package Jabbot::Plugin::zh_tw::DateDay;
use v5.18;
use utf8;
use Object::Tiny qw(core);

my %ZhDay = (
    MON => "星期一",
    TUE => "星期二",
    WED => "星期三",
    THU => "星期四",
    FRI => "星期五",
    SAT => "星期六",
    SUN => "星期日",
);

sub trim {
    for(@_) {
        s/^\s+//;
        s/\s+$//;
    }
}

sub can_answer {
    my ($self, $text) = @_;
    if ($text =~ /^(.*(?:號|日))(?:是)?(?:星期幾)?\s*/) {
        $self->{matched} = $1;
        return 1;
    }

    return 0;
}

sub day {
    my ($m, $d, $y) = @_;

    if ($m !~ /[\d]{1,2}/ || $m > 12  || $m < 1 ) { return "ERR"; }
    if ($d !~ /[\d]{1,2}/ || $d > 31  || $d < 1 ) { return "ERR"; }
    if ($y !~ /[\d]+/ || $y < 1 ) { return "ERR"; }

    my %month=(1,0,2,3,3,2,4,5,5,0,6,3,7,5,8,1,9,4,10,6,11,2,12,4,);
    my %weekday=(0,'SUN',1,'MON',2,'TUE',3,'WED',4,'THU',5,'FRI',6,'SAT',);

    if ($m == 1) { $y--; }
    if ($m == 2) { $y--; }

    $m = int($m);
    $d = int($d);
    $y = int($y);

    my $wday = (($d+$month{$m}+$y+(int($y/4))-(int($y/100))+(int($y/400)))%7);
    return $weekday{$wday};
}

sub answer {
    my $self = shift;
    my $target = $self->{matched};

    my $reply;
    my $p = '(.+)(?:號|日)';
    my $p0 = '(.+)月(.+)(?:號|日)';
    my $p1 = '(.+)年(.+)月(.+)(?:號|日)';
    my @now = localtime(time);
    if ($target =~ /$p1/) {
        my ($o,$m,$n) = ($1,$2,$3);
        trim($m,$n,$o);

        my $result = day($m,$n,$o);
        $reply = $ZhDay{$result};
    }
    elsif ($target =~ /$p0/) {
        my ($m,$n) = ($1,$2);
        trim($m,$n);

        my $result = day($m,$n,$now[5]+1900);
        $target = "今年" . $target;
        $reply = $ZhDay{$result};
    }
    elsif ($target =~ /$p/) {
        my $n = $1;
        trim($n);

        my $result = day($now[4]+1,$n,$now[5]+1900);
        $target = "這個月" . $target;
        $reply = $ZhDay{$result};
    }
    if(defined $reply) {
        $reply = "${target}是${reply}";
        return {
            body => $reply,
            score => 1
        }
    }
}


1;
