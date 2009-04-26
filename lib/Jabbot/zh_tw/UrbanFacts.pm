package Jabbot::zh_tw::UrbanFacts;
use Jabbot::Plugin -Base;
use utf8;

my $ymodifiers = "好像|應該|就|也|乃|只|衹|真的|真";

const class_id => 'zh_tw__urban_facts';
field isadb => {}, -init => q{$self->load_isadb};

sub load_isadb {
    io($self->plugin_directory)->mkpath;
    my $db = io->catfile($self->plugin_directory ,'main.db')->utf8->assert;
    $self->isadb($db);
    return $db;
}

sub process {
    my $msg = shift;
    my $qstring = $msg->text;
    my $r;
    return unless($msg->to eq $self->config->{nick});
    $qstring =~ s/^(.*)是誰\s*(\?|？)$/誰是$1？/;

    if ($qstring =~ /^誰是/) { $qstring .= "？" }

    if($qstring =~ /(\?|？)$/ ) {
	$qstring =~ s/(?:\?|？|\s)+$//;
	if($msg->to eq $self->config->{nick}) {
            $qstring =~ s/你/我/g;
	}
	if ($qstring =~ /^誰是\s*(.*?)\s*$/) {
            $r = $self->_queryWhoIsWhat($qstring);
	} elsif ($qstring =~ /^(什|甚)麼是(?!什麼)/) {
            my $q = $qstring;
            $q =~ s/^(.*)是//;
            $r = $self->queryWhatIsThat($q);
	} elsif ($qstring =~ /是(?!什麼)/) {
            $r = $self->_queryWhatIsWhat($qstring)
		if($msg->to eq $self->config->{nick})
	} elsif ($qstring =~ /是什麼/) {
            $qstring =~ s/\s*是什麼//;
	}
        $r = $self->isadb->{$qstring} if defined $self->isadb->{$qstring};
    } else {
        eval { $r = $self->do_my_job($qstring,$msg) }
            or print $@;
    }
    delete $self->isadb->{''};
    $self->reply($r,1);
}

sub do_my_job {
    my ($what,$msg) = @_;
    my $db = $self->isadb;
    $self->strip_meanless_tsi($what);
    $what =~ s/你/我/g if $msg->to eq $self->config->{nick};
    my @sentances = split(/。/, $what);
    my $r;
    my @rdb =qw(ok hmm 喔 了解 原來如此 我知道了 原來如此阿！ 記住了 所以？);
    my $TOKEN = '(?:是|很)';
    for (@sentances) {
        if (/$TOKEN/) {
            my ($k,$v) = split(/(?:不)?(?:$ymodifiers)?$TOKEN/ , $_, 2);
            $k =~ s/\s+$//;
            if($db->{$k}) {
                $r = $db->{$k};
            } else {
                $db->{$k} = $_;
                $r = $self->rand_choose(@rdb);
            }
        }
    }
    return $r;
}

sub strip_meanless_tsi {
    $_[0] =~ s/^其實(，|,)*//x ;
    $_[0] =~ s/(?:吧|喔)$//x ;
    $_[0];
}

sub _queryWhoIsWhat {
    my $db = $self->isadb;
    my $qstring = shift;
    my $r;

    my @fuzzyans;
    my $wanted = $1;
    $wanted =~ s/呢$//;
    if (length($db->{$wanted}) > 0) {
	push @fuzzyans,$wanted;
    }

    $wanted = quotemeta($wanted);
    foreach (keys %$db) {
	my $realv; $realv = $db->{"$_"};
	if ( $realv =~ m/$wanted/ ) {
	    push @fuzzyans,$_;
	}
    }
    if(scalar @fuzzyans > 0) {
	my $v = $db->{$self->rand_choose(@fuzzyans)};
	my $who = undef;
	if ($v =~ /^(.+?)\s*是$wanted$/) {
	    $who = $1;
	}
	if($who) {
	    $r = $who;
	} else {
	    $r = "我聽說過: $v";
	}
    } else {
	$r = "我不知道 \@_\@";
    }
    return $r;
}

sub queryWhatIsThat {
    my $qstring = shift;
    my $realv = $self->isadb->{$qstring};
    return $realv|| $self->rand_choose("不清楚","沒聽過","我也不知道");
}

sub _queryWhatIsWhat {
    my $qstring = shift;
    my $r;
    my ($k,$v) = split(/(?:不)?(?:$ymodifiers)?是/ , $qstring, 2);
    $k =~ s/\s+$//;
    my $realv = $self->isadb->{$k};
    if(length($realv) > 0 && length($v) > 0) {
	my (undef,$v2) = split(/(?:不)?(?:$ymodifiers)?是/ , $realv, 2);
	if ($qstring eq $realv) {
	    $r = "是啊";
	} elsif ( $v2 =~ m/$v/ || $v =~ m/$v2/ ) {
	    $r = $self->rand_choose("好像","應該","可能")
		. $self->rand_choose("是","")
                    . $self->rand_choose("吧","喔","呢");
	} else {
	    $r = $self->rand_choose("不是吧？","搞錯啦","不是這樣子的","並不是","是嗎？");
	}
    }
    return $r;
}
