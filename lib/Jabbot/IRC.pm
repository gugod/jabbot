package Jabbot::IRC;
use Jabbot::Base -Base;
use Net::IRC;
use Encode qw(encode decode);
use YAML;

field irc  => {}, -init => 'new Net::IRC';
field conn => {};

# $self in $conn handlers refers to a Net::IRC::Connection object
# So Jabbot::IRC object is kept in this lexical variable.
# We do love lexical scoping so much, don't we ?
my $bot;

sub process {
    $bot = $self;
    $self->use_class('config');
    my $conn = $self->irc->newconn(
        Server => $self->config->{irc_server},
        Nick => $self->config->{nick},
       );
    $conn->add_global_handler( 376, \&on_connect );
    $conn->add_handler("public",\&on_public);
    $self->conn($conn);
    $self->irc->start;
}

sub on_connect {
    for(@{$bot->config->{irc_channels}}) {
        $self->join($_);
	warn "joined $_\n";
    }
}

sub on_public {
    my $event   = shift;
    my $channel = lc(( $event->to )[0]);
    my $nick    = $event->nick;
    my $text    = decode('big5',( $event->args )[0]);
    my $hub     = $bot->hub;
    my $reply   = $bot->hub->process($text);
    warn "[$nick] $text\n";
    warn "[$channel] $reply\n";
    $self->privmsg($channel,encode('big5',$reply));
}
