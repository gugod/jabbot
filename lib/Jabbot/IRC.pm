package Jabbot::IRC;
use Jabbot::Base -Base;
use Net::IRC;

field nick => 'jabbot3';

field server => 'irc.freenode.net';
field irc  => {}, -init => 'new Net::IRC';
field conn => {};

my $bot;

sub process {
    $bot = $self;
    my $conn = $self->irc->newconn(
        Nick => $self->nick,
        Server => $self->server,
       );
    $conn->add_global_handler( 376, \&on_connect );
    $conn->add_handler("public",\&on_public);
    $self->conn($conn);
    $self->irc->start;
}

sub on_connect {
    $self->join("#jabbot3");
    warn "joined #jabbot3\n";
}

sub on_public {
    my $event   = shift;
    my $channel = lc(( $event->to )[0]);
    my $nick    = $event->nick;
    my $text    = ( $event->args )[0];
    my $hub     = $bot->hub;
    my $reply   = $bot->hub->process($text);
    warn "[$nick] $text\n";
    warn "[$channel] $reply\n";
    $self->privmsg($channel,$reply);
}
