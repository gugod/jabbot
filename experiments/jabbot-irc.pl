#!/usr/bin/perl

# This is a simple IRC bot that just echo back messages.

use warnings;
use strict;

use POE;
use POE::Component::IRC;

sub CHANNEL () { "#botchat" }

# Create the component that will represent an IRC network.
POE::Component::IRC->new("ircnet");

# Create the bot session.  The new() call specifies the events the bot
# knows about and the functions that will handle those events.
POE::Session->new
  ( _start => \&bot_start,
    irc_001    => \&on_connect,
    irc_public => \&on_public,
  );

# The bot session has started.  Register this bot with the "ircnet"
# IRC component.  Select a nickname.  Connect to a server.
sub bot_start {
    my $kernel  = $_[KERNEL];
    my $heap    = $_[HEAP];
    my $session = $_[SESSION];

    $kernel->post( ircnet => register => "all" );

    my $nick = 'jabbot3';
    $kernel->post( ircnet => connect =>
          { Nick => $nick,
            Username => 'jabbot3',
            Ircname  => 'POE::Component::IRC cookbook bot',
            Server   => 'irc.tw.freebsd.org',
            Port     => '6667',
          }
    );
}

# The bot has successfully connected to a server.  Join a channel.
sub on_connect {
    $_[KERNEL]->post( ircnet => join => CHANNEL );
}

# The bot has received a public message.  Parse it for commands, and
# respond to interesting things.
sub on_public {
    my ( $kernel, $who, $where, $msg ) = @_[ KERNEL, ARG0, ARG1, ARG2 ];
    my $nick = ( split /!/, $who )[0];
    my $channel = $where->[0];

    my $ts = scalar localtime;
    print " [$ts] <$nick:$channel> $msg\n";

    if ( my ($rot13) = $msg =~ /^jabbot3[:,]\s*(.+)/ ) {
        $kernel->post( ircnet => privmsg => CHANNEL, $rot13 );
    }
}

# Run the bot until it is done.
$poe_kernel->run();
exit 0;

