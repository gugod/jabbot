#!/usr/local/bin/perl

BEGIN {push @INC, "../lib";}

use strict;

use Jabbot::Lib;
use Jabbot::ModLib;

my $priority = 0;
my $s = $MSG{body};
my $r;

# This command is executed only if some user is talking to me.
#exit(0) unless ($MSG{to} eq $BOT_NICK);
# Response only if the input looks like a standard "echo"
if($s =~ /^dict (\w+)$/) {
    eval {
	local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
        alarm(10);
        $r = get_dict_data($1);
        alarm(0);
    };
    if($@) {
        die "Timeout";
    }
} else {
  exit(0);
}

# priority is suggest to be non-zero ONLY if you have
# quite positive response. Lager value means higher priority.
$priority = 1000;

# Reply it.
reply({ from => $BOT_NICK,
	to   => $MSG{to},
	body => $r,
	priority => $priority
    });
1;

sub get_dict_data {
    my $word = shift;
    #$data =~ s/ //;
    #my ($key,$word) = split(/,/,$data);
    #exit unless ($key eq 'dict');

    use HTTP::Request::Common qw(GET);
    use LWP::UserAgent;
    use Encode;
    my $ua = LWP::UserAgent->new(timeout => 300) or die $!;;
    my $res = $ua->request(
                  GET 'http://kalug.linux.org.tw/~chihchun/dict/index.php?op=search'.
	          '&word='.$word.'&strategy=*&database=*'
	      );

    if ($res->is_success) {
	my $data = $res->{_content};
        while ($data =~ s/(<pre>)(.+?)(<\/pre>)//s) {
	    my $get = $2;
	    $get =~ s/<.+?>//gs;
	    $get =~ s/\s+/ /is;
	    Encode::from_to($get, "utf8", "big5");
	    return $get;
	}
    } else {
	return $res->as_string;
    };

}
