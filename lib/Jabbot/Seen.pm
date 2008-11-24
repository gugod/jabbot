package Jabbot::Seen;
use Jabbot::Plugin -Base;
use Time::Interval;

const class_id => 'seen';

sub process {
    my $msg = shift;
    my $nick = $msg->from;
    my $db = io->catfile($self->plugin_directory,"seen.db")->assert;
    my $reply;
    if($msg->text =~ /^seen\s+([^\s\?]+)\s*\?*/) {
	if(defined($db->{$1})) {
	    my $t1 = gmtime($db->{$1}) . " GMT";
	    my $t2 = gmtime(time) . " GMT";
	    my $interval = getInterval($t1,$t2);
	    $reply = "$1 was seen ";
	    for(qw(days hours minutes seconds)) {
		if($interval->{$_}) {
		    $reply .= "$interval->{$_} $_ ";
		}
	    }
	    $reply .= 'ago';
	} else {
	    $reply = "I havn't seen $1, $nick";
	}
    }
    $db->{$nick} = time;

    eval {
        tied(%{$db->tied_file})->sync;
    };
    if ($@) {
        print "??? sync failed\n";
    }

    $self->reply($reply,1);
}

