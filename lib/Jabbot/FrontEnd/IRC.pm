package Jabbot::FrontEnd::IRC;
use Jabbot::FrontEnd -Base;
use Net::IRC;
use Encode qw(encode decode);
use YAML;

field irc  => {}, -init => 'new Net::IRC';
field conn => {};

# $self in $conn handlers refers to a Net::IRC::Connection object
# So Jabbot::IRC object is kept in this lexical variable.
# We do love lexical scoping so much, don't we ?
my $bot;
my $conn;

sub on_alarm {
    my $hub     = $bot->hub;
    my $msg     = $hub->process('');
    if(defined($msg->text)) {
        my $reply   = $msg->text;
        my $channel = $msg->channel || '#jabbot3';
        warn "[$channel] $reply\n";
        $self->privmsg($channel,encode('big5',"$nick: $reply"));
        $conn->privmsg($channel,'dood');
        alarm(10);
    }
}

sub process {
    $SIG{ALRM} = \&on_alarm;
    $bot = $self;
    $self->use_class('config');
    $conn = $self->irc->newconn(
        Server => $self->config->{irc_server},
        Nick => $self->config->{nick},
       );
    $conn->add_global_handler( 376, \&on_connect );
    $conn->add_handler("public",\&on_public);
    $self->conn($conn);
    alarm(10);
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
    my $to = sub {
	return '' if($_[0] =~ /^http/i);
	if($_[0] =~ s/^([\d\w\|]+)\s*[:,]\s*//) { return $1; }
	return '';
    }->($text);
    warn "[$nick] $text\n";
    my $hub     = $bot->hub;
    my $msg     = $hub->process($text);
    if($to eq $bot->config->{nick} || $msg->must_say) {
        my $reply   = $msg->text;
	warn "[$channel] $reply\n";
	$self->privmsg($channel,encode('big5',"$nick: $reply"));
    }
}
