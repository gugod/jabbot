package Jabbot::Karma;
use Jabbot::Plugin -Base;

const class_id => 'karma';

sub process {
    my $msg = shift;
    my $s = $msg->text;
    my $reply;
    my $db = io->catfile($self->plugin_directory,"karma.db")->assert;
    if($s =~ /\S(?:\+\+|\-\-)(?:\s|$)/) {
        my $k = $self->getKeyword($s);
        if ( $s =~ m/\+\+/ ) {
            ($db->{$k})++;
        } elsif ( $s =~ m/\-\-/ ) {
            ($db->{$k})--;
        }

        $reply = "ok, " . $msg->from;
    } elsif ($s =~ /^karma\s+scoreboard\s*$/i) {
        $reply = join (", ", map {
            "$_(" . $db->{$_} .")"
        } grep {defined$_}(sort { $db->{$b} <=> $db->{$a} } keys %$db)[0..10]);
    } elsif ($s =~ /^negative\s+karma\s+scoreboard\s*$/i) {
        $reply = join (", ", map {
            "$_(" . $db->{$_} .")"
        } grep {defined$_} (sort { $db->{$a} <=> $db->{$b} } keys %$db)[0..10]);
    } elsif ($s =~ /^karma\s+(.+)\s*$/) {
        my $nword = lc($1);
        my $karma = $db->{$nword} || sub {
                    for(keys %$db) {
                        return $db->{$_} if($self->normalizeWord($_) eq $nword);
                    }
                    return 0; 
		}->();
        $reply = ($karma == 0)?"$1 has neutral karma":"$1 has karma of $karma";
    }
    $self->reply($reply,1);
}

sub normalizeWord {
	my $str = lc(shift);
        return $str;
}

sub getKeyword {
    my $str = shift;
    $str =~ s/(?:\+\+|--).*$//;
    # Quoted by quote, or determined by whitespaces
    if($str =~ /([\'\"\(\[\{])(.*)([\'\"\)\]\}])$/) {
	$str = $2;
    } else {
	$str = (split(/ /,$str))[-1];
    }
    return $self->normalizeWord($str);
}

