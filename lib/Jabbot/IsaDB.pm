package Jabbot::IsaDB;
use Jabbot::Plugin -Base;
use utf8;

my $ymodifiers = "好像|應該|就|乃|只|衹|真的|真";

const class_id => 'isa_db';
field isadb => {}, -init => q{$self->load_isadb};

sub load_isadb {
    io($self->plugin_directory)->mkpath;
    my $db = io->catfile($self->plugin_directory,'isa.db')->utf8->assert;
    $self->isadb($db);
    return $db;
}

sub process {
#    eval { $self->load_isadb } or print $@;
    my $msg = shift;
    my $qstring = $msg->text;
    my $r;
    return unless($msg->to eq $self->config->{nick});
    $qstring =~ s/^(.*)是誰\s*(\?|？)$/誰是$1？/;

    if ($qstring =~ /^誰是/) {$qstring .= "？"}
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
    } elsif($qstring =~ /^(?:(?:(?:dump|(?:tell me)) all keywords about)|(?:what do you know about))\s+([^\?]+)[\s\?]*$/) {
	my $wanted = quotemeta($1);
	my @iknow = grep { $_ =~ /$wanted/i } keys %{$self->isadb};
	if(@iknow) {
	    $r = "一共有 " .( $#iknow + 1) ." 筆: " . join(" || ", @iknow);
	    $r = "一共有 ". ($#iknow + 1) ." 筆, 實在太多了"
		if (length($r) > 400);
	}
	$r ||= "我啥都不知道，別打我";
    } elsif($qstring =~ /^(?:dump|(?:tell me)) all about\s+(.*)\s*$/) {
	my $wanted = quotemeta($1);
	my @iknow = grep { $_ =~ /$wanted/i } keys %{$self->isadb};
	my $k = scalar(@iknow);
	$k = 3 if $k > 3;
	$r = join("。", map {$self->isadb->{$_}} (sort { rand() <=> rand() } @iknow)[0..$k]);
	$r = "太多了，三天三夜說不完" if (length($r) > 400);
	$r ||= "我啥都不知道，別打我";
    } elsif($qstring =~ /^forget all about\s+(.*)\s*$/ && $msg->to eq $self->config->{nick}) {
	my $wanted = quotemeta($1);
	my $n = 0 ;
	map { $n++; delete $self->isadb->{$_} }
            grep { $_ =~ /$wanted/ }
                keys %{$self->isadb};
	$r= ($n == 0)? "並無任何與 $1 有關的資料"
            : "一共有 $n 筆資料從資料庫中永遠刪除了";
    } elsif($qstring =~ /(?:anything\s+about\s+)(.*)\s*(\?!!!+)/ && $msg->to eq $self->config->{nick}) {
	my $wanted = quotemeta($1);
	$r = $self->rand_choose(map {$self->isadb->{$_}} grep { $_ =~ /$wanted/ } keys %{$self->isadb});
    } elsif($qstring =~ /^forget\s+(.*)$/  && $msg->to eq $self->config->{nick}) {
	delete $self->isadb->{$1};
	$r= "ok";
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
        } elsif (/(.+)\sis\salso\s(.+)/i) {
            my ($k,$v) = ($1,$2);
            $k =~ s/\s+$//;
            if(length($db->{$k}) > 0) {
                $db->{$k} = $v;
            } else {
                $db->{$k} .= " or $v";
            }
            $r = $self->rand_choose(@rdb);
        } elsif (/\s[Ii][Ss]\s/) {
            my ($k,$v) = split(/\s[Ii][Ss]\s/ , $_, 2);
            $k =~ s/\s+$//;
            $self->isadb->{$k} = $_;
            $r = $self->rand_choose(@rdb);
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
    my $realv; $realv = $self->isadb->{$k};
    my ($k2,$v2) = split(/(?:不)?(?:$ymodifiers)?是/ , $realv, 2);
    if(length($realv) > 0 && length($v) > 0) {
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
