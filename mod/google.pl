#!/usr/local/bin/perl

BEGIN { push @INC, "../lib"; }

use strict;
use Tie::Google ;
my $KEYFILE = "$ENV{HOME}/.googlekey";

use Encode qw/decode/;

use Jabbot::Lib;
use Jabbot::ModLib;

my $qstring = $MSG{body};
my $reply;
if($MSG{to} eq $BOT_NICK && $qstring =~ /^google\s+(.+)$/) {
    $reply = google_search(decode("big5",$1));
} elsif($MSG{to} eq $BOT_NICK &&
	$qstring =~ /^googlefight\s+((.+)\s+(vs\s+(.+))+)$/) {
    my @q = split(/\s+vs\s+/,$1);
    my @uq = @q;
    use Encode qw(from_to);
    foreach (@uq) { from_to($_ ,"big5","utf-8") }
    my @n = googlefight(@uq);
#    print STDERR "[googlefight] " . join(" vs ",@q);
    my %r;
    for my $i (0..$#q) {
	$r{$q[$i]} = $n[$i]
    }
    $reply = join(" > ", map { "$_ ($r{$_})" }
			sort { $r{$b} <=> $r{$a} } keys %r );
}

reply({ from => $BOT_NICK ,
	to   => $MSG{from},
	priority => 1000,
	body => $reply
});

sub google_search {
	my $what = shift;
	tie my $g, "Tie::Google", $KEYFILE, "$what";
	my $r = $g->{URL};
	return $r if $r;
	return rand_choose(
		"Bad luck this time!" ,
		"Try different words!" ,
		"Google ain't finding anything",
		"You aren't feeling lucky",
		"Try altavista next time",
		"Use the force; Luke",
		"Want some coffee ?",
		"Are you serious ?"
		);
	;
}

sub googlefight {
    # Input data are forced to be utf8.
    return 
	map { s/,//g; $_ }
	map { googlefight_get_result($_) } @_;
}

sub googlefight_get_result {
    use DB_File;
    use URI::Escape;

    my $q = shift;
 
    my $r;
    my %googlefight_cache;
    tie %googlefight_cache, 'DB_File', "${DB_DIR}/googlefight_cache.db", O_CREAT|O_RDWR ;
    if($googlefight_cache{$q}) {
	$r= $googlefight_cache{$q};
	untie %googlefight_cache;
	return $r;
    }

    my $url= "http://www.google.com.tw/search?ie=UTF-8&oe=UTF-8&hl=zh-TW&btnG=Google+%E6%90%9C%E5%B0%8B&lr=&q=";

    my $safe = uri_escape($q);

    my $data;
    local $/ = undef;

    open(FH,"/usr/local/bin/w3m -dump_source '${url}${safe}' |");
    $data = <FH>;
    close(FH);

    $r = _googlefight_grep_total_results($data);
    $googlefight_cache{$q}=$r;
    untie %googlefight_cache;
    return $r;
}

sub _googlefight_grep_total_results {
    my $data = shift;
    if($data =~ m{有<b>(.+?)</b>項查詢結果}s) { return $1; }
    return 0;
}
