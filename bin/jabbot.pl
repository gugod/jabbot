#!/usr/bin/perl
# 	$Id: jabbot.pl,v 1.9 2002/06/16 14:20:03 gugod Exp $
#

use strict;
use lib qw/.. ./;
use IO::Handle;
use Net::IRC;
use Time::localtime;
use DB_File;
use IPC::Open2;
use File::Glob ':glob';
use POSIX ":sys_wait_h";
use IO::All;
use YAML;

use Jabbot::Lib;
use POSIX ":sys_wait_h";
my %Kid_Status;
sub REAPER {
	my $child;
	while (($child = waitpid(-1,WNOHANG)) > 0) {
		$Kid_Status{$child} = $?;
	}
	$SIG{CHLD} = \&REAPER;
}
$SIG{CHLD} = \&REAPER; 

$|++;
local $/;

my $DEBUG = 1;

my $reply;
my $verbose = 0;

my $config = YAML::LoadFile('config.yaml');

my $server     = $config->{server};
my $mynick     = $config->{nick} || $BOT_NICK;

my  %channels;
$channels{botchat} = 1;

my $irc  = new Net::IRC;
my $conn = $irc->newconn(
		Nick      => $mynick,
		Server    => $server,
		Port      => 6666,
		Ircname   => "Bato Ro",
		Username  => "jabo"
		);

my @bot_module;
reload_modules();

autoflush STDOUT 1;
autoflush STDERR 1;

# log
my $logfh = io("${BOT_HOME}/log/jabbot.log")->assert;
sub printlog { $logfh->append(shift); }

$conn->add_handler("public",   \&on_public);
$conn->add_global_handler( 376, \&on_connect );
$conn->add_global_handler( 'disconnect', \&on_disconnect );
$conn->add_handler("invite",  \&on_invite);

$SIG{INT} = \&shutdown_bot;
$SIG{USR1} = \&reconnect_bot;

my %ignores;
tie %ignores, 'DB_File', "${DB_DIR}/ignorenicks.db", O_CREAT|O_RDWR ;

$irc->start;
# 
sub reconnect_bot {
	$conn->quit("Bye");
	print_log("$mynick reconnect\n");
	reload_modules();
	untie %ignores;
	tie %ignores, 'DB_File', "${DB_DIR}/ignorenicks.db", O_CREAT|O_RDWR ;
}

sub shutdown_bot {
	$conn->quit("Bye");
	printlog "$mynick exit\n";
	exit;
}


# Setup bot's module.
sub reload_modules {
	chdir(${MOD_DIR});
	@bot_module = bsd_glob("*.pl");
	chdir("-");

}

sub on_invite {
	my ( $self, $event ) = @_;
	my $channel     = lc(( $event->args )[0]);
	my $nick    = $event->nick;
	tie %channels, 'DB_File', "${DB_DIR}/channels.db", O_CREAT|O_RDWR ;
	$channels{$channel} = 1;
	untie %channels;
	$self->join($channel);
}

sub on_disconnect {
	my ( $self, $event ) = @_;
	$self->connect();
}

sub on_connect {
	my $self = shift;
	tie %channels, 'DB_File', "${DB_DIR}/channels.db", O_CREAT|O_RDWR ;
	foreach (keys %channels) {
		$self->join($_);
	}
	untie %channels;
	printlog "$mynick has joined $server\n";
}

sub on_public {
	my ( $self, $event ) = @_;
	my $channel = lc(( $event->to )[0]);
	my $nick    = $event->nick;
	my $str     = ( $event->args )[0];
	my $time = sprintf( "%02d:%02d", localtime->hour(), localtime->min() );
	printlog "($channel) $time <$nick> $str\n";
	my $to = strip_leading_nick($str);

	foreach (keys %ignores) {
		if ($nick eq $_){
			return;
		}
	}

# a real dirty hack :p

	if($str =~ /^reload modules$/i) {
		if(grep /^$nick$/,@{$config->{admin}}) {
			reload_modules();
			$self->privmsg($channel, "$nick: ok");
		}else {
			$self->privmsg($channel, "$nick: no way.");
		}
		return;
	}elsif(($str =~/^part$/i)&& $to eq $mynick) {

		tie %channels, 'DB_File', "${DB_DIR}/channels.db", O_CREAT|O_RDWR ;
		delete $channels{$channel} ;
		untie %channels;
		$self->part($channel);
		return;
	}

	my @r;
	foreach ( @bot_module ){
#		next if (rand(10) > 50);
		next unless(-x "${MOD_DIR}/$_");
		my $pid = open2(\*RDRFH, \*WTRFH, "${MOD_DIR}/$_");
		print WTRFH msg2txt({ from => $nick,
				to   => $to,
				body => $str
				});
		close(WTRFH);
		undef $/;
		my $r = <RDRFH>;
		my %rmsg = txt2msg($r);
		close(RDRFH);
		push @r,\%rmsg;
	}

	@r = sort { $b->{priority} <=> $a->{priority} }
	grep { length($_->{body}) > 0 } @r;

	my $reply ;
	if ($r[0]->{priority} == 0 ) {
		$reply = $r[int(rand($#r))];
	} else {
		$reply = $r[0];
	}
	my @msgs = split(/\n/,$reply->{body});
	if ($#msgs > 3) {
		$self->privmsg($nick, $_) foreach(@msgs);
	} else {
		if(length($reply->{to}) >0 ) {
			$self->privmsg($channel, "$nick: $_")
				foreach(@msgs);
		} elsif($reply->{public} || ($reply->{priority} > 0) ) {
			$self->privmsg($channel, $_)
				foreach(@msgs);
		}
	}
#wait foreach(@bot_module);
}


