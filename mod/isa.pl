#!/usr/local/bin/perl

BEGIN { push @INC, "../lib"; }

use strict;
use DB_File;
use Encode qw/decode/;

use Jabbot::Lib;
use Jabbot::ModLib;

my $qstring = $MSG{body};

my %isadb;
tie %isadb, 'DB_File', "${DB_DIR}/isa.db", O_CREAT|O_RDWR ;

my $ymodifiers = "¦n¹³|À³¸Ó|´N|¤D|¥u|°N|¯uªº|¯u";
my $priority = 0;
my $r;

$qstring =~ s/^(.*)¬O½Ö\s*(\?|¡H)$/½Ö¬O$1¡H/;

if ($qstring =~ /^½Ö¬O/) {
	$qstring .= "¡H";
}
if($qstring =~ /(\?|¡H)$/ ) {
	# Don't reply anything if I'm not been asked.
    	exit(0) unless($MSG{to} eq $BOT_NICK) ;
	$qstring =~ s/(?:\?|¡H|\s)+$//;
	if($MSG{to} eq $BOT_NICK) {
		$qstring =~ s/§A/§Ú/g;
	}
	if ($qstring =~ /^½Ö¬O\s*(.*?)\s*$/) {
		$r = _queryWhoIsWhat($qstring);
	} elsif ($qstring =~ /^(¤°|¬Æ)»ò¬O(?!¤°»ò)/) {
		my $q = $qstring;
		$q =~ s/^(.*)¬O//;
		$r = _queryWhatIsThat($q);
	} elsif ($qstring =~ /¬O(?!¤°»ò)/) {
		$r = _queryWhatIsWhat($qstring);
	} elsif ($qstring =~ /¬O¤°»ò/) {
		$qstring =~ s/\s*¬O¤°»ò//;
	}
        if(length($isadb{"$qstring"}) > 0) {
		$r = $isadb{"$qstring"};
		$priority = 1000;
	}
} elsif($qstring =~ /^(?:(?:(?:dump|(?:tell me)) all keywords about)|(?:what do you know about))\s+([^\?]+)[\s\?]*$/) {
	my $wanted = quotemeta($1);
	my @iknow = grep { $_ =~ /$wanted/i } keys %isadb;
	if(@iknow) {
	    $r = "¤@¦@¦³ " .( $#iknow + 1) ." µ§: " . join(" || ", @iknow);
	    $r = "¤@¦@¦³ ". ($#iknow + 1) ." µ§, ¹ê¦b¤Ó¦h¤F"
		if (length($r) > 400);
	}
	$r ||= "§ÚÔ£³£¤£ª¾¹D¡A§O¥´§Ú";
} elsif($qstring =~ /^(?:dump|(?:tell me)) all about\s+(.*)\s*$/) {
	my $wanted = quotemeta($1);
	my @iknow = grep { $_ =~ /$wanted/i } keys %isadb;
	my $k = scalar(@iknow);
	$k = 3 if $k > 3;
	$r = join("¡C", map {$isadb{$_}} (sort { rand() <=> rand() } @iknow)[0..$k]);
	$r = "¤Ó¦h¤F¡A¤T¤Ñ¤T©]»¡¤£§¹" if (length($r) > 400);
	$r ||= "§ÚÔ£³£¤£ª¾¹D¡A§O¥´§Ú";
} elsif($qstring =~ /^forget all about\s+(.*)\s*$/ && $MSG{to} eq $BOT_NICK) {
	my $wanted = quotemeta($1);
	my $n = 0 ;
	map { $n++; delete $isadb{$_} }
	grep { $_ =~ /$wanted/ }
	keys %isadb;
	$r= ($n == 0)? "¨ÃµL¥ô¦ó»P $1 ¦³Ãöªº¸ê®Æ"
	 : "¤@¦@¦³ $n µ§¸ê®Æ±q¸ê®Æ®w¤¤¥Ã»·§R°£¤F";
} elsif($qstring =~ /(?:anything\s+about\s+)(.*)\s*(\?!!!+)/ && $MSG{to} eq $BOT_NICK) {
	my $wanted = quotemeta($1);
	$r = rand_choose(map {$isadb{$_}} grep { $_ =~ /$wanted/ } keys %isadb);
} elsif($qstring =~ /^forget\s+(.*)$/  && $MSG{to} eq $BOT_NICK) {
	delete $isadb{$1};
	$r= "ok";
} elsif(length($isadb{"$qstring"}) > 0 && rand(20) > 17) {
	$r= $isadb{"$qstring"};
} else {
	$r = do_my_job($qstring);
}

delete $isadb{''};
untie %isadb;

if(length($r) > 0) {
    $priority += 10000;
}

reply({from => $BOT_NICK,
       to   => $MSG{from},
       priority => $priority,
       body => $r});

sub do_my_job {
	my $what = shift;
	strip_meanless_tsi($what);
	if($MSG{to} eq $BOT_NICK) {
		$what =~ s/§A/§Ú/g;
	}
	my @sentances = split(/¡C/, $what);
	my $r;
	my @rdb =qw(ok ¤F¸Ñ Á ­ì¨Ó¦p¦¹ §Úª¾¹D¤F ­ì¨Ó¦p¦¹ªü¡I °O¦í¤F ©Ò¥H¡H);
	my $TOKEN = '(?:¬O|«Ü)';
	foreach (@sentances) {
		if (/$TOKEN/) {
			my ($k,$v) = split(/(?:¤£)?(?:$ymodifiers)?$TOKEN/ , $_, 2);
			$k =~ s/\s+$//;
			if(exists $isadb{"$k"}) {
				$r = "¤£¹L¡A¾Ú§Ú©Òª¾¡A$isadb{$k}";
			} else {
				$isadb{"$k"} = $_;
				$r = rand_choose(@rdb);
			}
		} elsif (/(.+)\sis\salso\s(.+)/i) {
			my ($k,$v) = ($1,$2);
			$k =~ s/\s+$//;
			if(length($isadb{$k}) > 0) {
			    $isadb{$k} = $v;
			} else {
			    $isadb{$k} .= " or $v";
			}
			$r = rand_choose(@rdb);
		} elsif (/\s[Ii][Ss]\s/) {
			my ($k,$v) = split(/\s[Ii][Ss]\s/ , $_, 2);
			$k =~ s/\s+$//;
			$isadb{$k} = $_;
			$r = rand_choose(@rdb);
		}
	}
	return $r if($MSG{to} eq $BOT_NICK);
}

sub strip_meanless_tsi {
	$_[0] =~ s/^¨ä¹ê(¡A|,)*//x ;
	$_[0] =~ s/(?:§a|³á)$//x ;
	$_[0];
}

sub _queryWhoIsWhat {
    my $qstring = shift;
    my $r;

    my @fuzzyans;
    my $wanted = $1;
    $wanted =~ s/©O$//;
    if (length($isadb{"$wanted"}) > 0) {
	push @fuzzyans,$wanted;
    }

    $wanted = quotemeta($wanted);
    foreach (keys %isadb) {
	my $realv; $realv = $isadb{"$_"};
	if ( $realv =~ m/$wanted/ ) {
	    push @fuzzyans,$_;
	}
    }
    if(scalar @fuzzyans > 0) {
	my $v = $isadb{rand_choose(@fuzzyans)};
	my $who = undef;
	if ($v =~ /^(.+?)\s*¬O$wanted$/) {
	    $who = $1;
	}
	if($who) {
	    $r = $who;
	    $priority = 1000;
	} else {
	    $r = "§ÚÅ¥»¡¹L: $v";
	}
    } else {
	$r = "§Ú¤£ª¾¹D \@_\@";
    }
    return $r;
}

sub _queryWhatIsThat {
    my $qstring = shift;
    my $realv = $isadb{"$qstring"};
    return $realv|| rand_choose("¤£²M·¡","¨SÅ¥¹L","§Ú¤]¤£ª¾¹D");
}

sub _queryWhatIsWhat {
    my $qstring = shift;
    my $r;
    my ($k,$v) = split(/(?:¤£)?(?:$ymodifiers)?¬O/ , $qstring, 2);
    $k =~ s/\s+$//;
    my $realv; $realv = $isadb{"$k"};
    my ($k2,$v2) = split(/(?:¤£)?(?:$ymodifiers)?¬O/ , $realv, 2);
    if(length($realv) > 0 && length($v) > 0) {
	if ($qstring eq $realv) {
	    $r = "¬O°Ú";	
	} elsif ( $v2 =~ m/$v/ || $v =~ m/$v2/ ) {
	    $r = rand_choose("¦n¹³","À³¸Ó","¥i¯à")
		. rand_choose("¬O","")
		. rand_choose("§a","³á","©O");
	} else {
	    $r = rand_choose("¤£¬O§a¡H","·d¿ù°Õ","¤£¬O³o¼Ë¤lªº","¨Ã¤£¬O","¬O¶Ü¡H");
	}	
    }
    return $r;
}

