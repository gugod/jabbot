package Jabbot::FrontEnd::IRC;
use Jabbot::FrontEnd -Base;

sub process {
    my $bot = Jabbot::FrontEnd::IRC::Bot->new(
        Nick => $self->config->{nick},
        Server => $self->config->{irc_server},
        Channels => $self->config->{irc_channels},
        LogPath => '/tmp/',
       );
    $bot->{jab} = $self;
    $bot->run();
}


package Jabbot::FrontEnd::IRC::Bot;
use POE;
use base 'IRC::Bot';
use Encode;
use YAML;

# Check POE/Session.pm for those myth values

sub on_public {
    unshift(@_,'dummy');
    my ($kernel,$who,$where,$msg) = @_[KERNEL,ARG0..$#_];
    my $nick = ( split /!/, $who )[0];
    my $channel = $where->[0];
    my $pubmsg  = Encode::decode('big5',$msg);
    my $to = sub {
       return '' if($_[0] =~ /^http/i);
       if($_[0] =~ s/^([\d\w\|]+)\s*[:,]\s*//) { return $1; }
       return '';
    }->($pubmsg);
    my $reply = $self->{jab}->hub->process($pubmsg);
    my $reply_text = $reply->text;
    if(length($reply_text) &&
           ($to eq $self->{jab}->config->{nick} || $reply->must_say)) {
        $reply_text = Encode::encode('big5',"$to: $reply_text");
        $self->botspeak($kernel,$channel,$reply_text);
    }
}
