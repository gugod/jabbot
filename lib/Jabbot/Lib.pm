
package Jabbot::Lib;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(rand_choose strip_leading_nick
	     trim_whitespace msg2txt txt2msg
	     reply
	     $BOT_HOME $MOD_DIR $DB_DIR
	     $BOT_NICK %MSG
	     );

our $BOT_NICK= "jabbot";
our $HOME=  $ENV{HOME};
our $BOT_HOME = "$ENV{HOME}/bot/$BOT_NICK";
our $MOD_DIR  = "${BOT_HOME}/mod";
our $DB_DIR  = "${BOT_HOME}/db";

sub strip_leading_nick {
    return undef if($_[0] =~ /^http/i);
    if($_[0] =~ s/^([\d\w\|]+)\s*[:,]\s*//) {
	return $1;
    }
    return undef;
}

sub rand_choose {
	return @_->[rand($#_ +1)];
}

sub trim_whitespace {
    map  {
	s/^\s+//;
	s/\s+$//;
	$_;
    } @_;
}

sub reply {
    print msg2txt(shift);
}

sub msg2txt {
    my $msg = shift;
    my $body = $msg->{body};
    delete $msg->{body};
    $msg->{priority} ||= 0;
    my $s;
    foreach (keys %${msg}) {
	$s .= "$_: " . $msg->{"$_"} . "\n";
    }
    $s .=  "\n${body}\n";
    $msg->{body} = $body;
    return $s;
}

sub txt2msg {
    my($hdr,$body) = split(/\n\n/, shift);
    my %msg;
    trim_whitespace($body);
    $msg{body} = $body;
    foreach (split(/\n/, $hdr)) {
	my($k,$v) = trim_whitespace(split ":");
	$msg{lc($k)} = $v;
    }
    return %msg;
}

1;
