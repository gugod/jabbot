package Jabbot::Karma;
use Jabbot::Plugin -Base;

const class_id => 'karma';

sub process {
    my $s = shift->text;
    my $reply;
    my $db = io->catfile($self->plugin_directory,"karma.db")->assert;
    if($s =~ /\S(?:\+\+|\-\-)(?:\s|$)/) {
        my $k = $self->getKeyword($s);
        if ( $s =~ m/\+\+/ ) {
            ($db->{$k})++;
        } elsif ( $s =~ m/\-\-/ ) {
            ($db->{$k})--;
        }
    } elsif ($s =~ /^karma\s+scoreboard\s*$/i) {
        $reply = join (", ", map {
            "$_(" . $db->{$_} .")"
        } grep {defined$_}(sort { $db->{$b} <=> $db->{$a} } keys %$db)[0..10]);
    } elsif ($s =~ /^negative\s+karma\s+scoreboard\s*$/i) {
        $reply = join (", ", map {
            "$_(" . $db->{$_} .")"
        } grep {defined$_} (sort { $db->{$a} <=> $db->{$b} } keys %$db)[0..10]);
    } elsif ($s =~ /^karma\s+(.+)\s*$/) {
        my $karma = $db->{$1} || 0;
        $reply = ($karma == 0)?"$1 has neutral karma":"$1 has karma of $karma";
    }
    $self->reply($reply,10000);
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
    return $str;
}

