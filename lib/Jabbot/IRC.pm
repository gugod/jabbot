
package Jabbot::IRC;

use Net::IRC;


sub on_invite {
        my ( $self, $event ) = @_;
        my $channel     = lc(( $event->args )[0]);
        my $nick    = $event->nick;
        $self->join($channel);
}

sub on_disconnect {
        my ( $self, $event ) = @_;
        print
	    "Disconnected from ",
	    $event->from(), " (", 
	    ( $event->args() )[0], "). Attempting to reconnect...\n";
        $self->connect();
}

sub on_connect {
        my $self = shift;
        foreach (@channels) {
                $self->join($_);
        }
        print "$mynick has joined $server\n";
}


1;
