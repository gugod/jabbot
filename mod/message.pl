#!/usr/local/bin/perl

BEGIN { push @INC, "../lib"; }

use strict;
use DB_File;
use Jabbot::Lib;
use Jabbot::ModLib;

my $s = $MSG{body};
my $reply;
my $priority = 0;
my $to       = $MSG{to};
my $nick     = $MSG{from};

normalize($nick);

if($s =~/^([^!\s]+)\s*!+\s*/) {
  my %MsgDB;
  tie %MsgDB, 'DB_File', "${DB_DIR}/message.db";
  my $nick = $1;
  normalize($nick);
  if(length($MsgDB{"$nick"}) > 0) {
    $reply = "$nick 有留言";
    reply({
      priority => 10000,
      from     => $BOT_NICK ,
      to       => "",
      public   => "yes",
      body     => $reply
    });
  }
  untie %MsgDB;
  exit(0);
}

my %MsgDB;
tie %MsgDB, 'DB_File', "${DB_DIR}/message.db";
# print STDERR  "[$s]\n";
my %LastNotifyDB;
tie %LastNotifyDB, 'DB_File', "${DB_DIR}/message-notify.db";

if($to eq $BOT_NICK && $s =~ /^(?:tell\s|告訴)\s*(.+?)[\s,]+(.+)\s*/) {
  # tell $somebody $blahblah
  my $somebody = $1;
  my $something = $2;
  normalize($somebody);
  if($somebody eq $BOT_NICK) {
	$reply = rand_choose("有事情直接跟我講就好了，幹麼留言？",
			"我還沒睡啦....直接跟我講就好了"
			);
  } elsif (length($MsgDB{"$somebody"}) > 0) {
# This is a really bad data structure. Don't learn it , good kiddie.
    $MsgDB{"$somebody"} .= " ,and from $nick: $something";
    my $m2 = ",and " . $MsgDB{"$somebody"};
    my @m3 = split(",and from",$m2);
    my %m4;
    foreach (@m3) {
      next if 0 == length($_);
      my ($nick, $msg) = split(/:/,$_,2);
      $nick =~ s/^\s+//;
      $msg =~ s/^\s+//; $msg =~ s/\s+$//; $msg =~ s/\.$//;
      if (length($m4{$nick})) {
	$m4{$nick} .= ". $msg";
      } else {
	$m4{$nick} = "$msg";
      }
    }

    my $total_msg = "";
    foreach (keys %m4) {
      my $m = $m4{$_};
#      print STDERR "($_,$m)\n";
      $total_msg .= " ,and from $_: $m";
    }
    $total_msg = substr($total_msg,6);
    $MsgDB{"$somebody"} = $total_msg;
  } else {
    $MsgDB{"$somebody"} = "from $nick: $something";
  }
  $reply= "ok" unless (length($reply)>0);
} elsif ($to eq $BOT_NICK && $s =~ /^((?:message|msg)s?\s*|.*留言.*)$/) {
  my $something = $MsgDB{"$nick"};
  if (length($something) > 0) {
    $reply = $something;
    undef $MsgDB{"$nick"};
  } else {
    $reply = "你沒有留言";
  }
} else {
    my $somebody = $MSG{from};
    normalize($somebody);
    # 每小時最多提醒一次
    if( (time - $LastNotifyDB{"$somebody"}) > 3600 &&
	    length($MsgDB{"$somebody"}) > 0) {
	$reply ="你有留言 (可用 ${BOT_NICK}: msg 看留言)";
	$LastNotifyDB{"$somebody"} = time ;
    }
}
untie %MsgDB;
untie %LastNotifyDB;

# print STDERR "[$reply]\n";

exit(0) unless(length($reply) > 0);

reply({
    priority => 10000,
    from     => $BOT_NICK ,
    to       => $MSG{from},
    body     => $reply
    });

# __Sub routines__
sub normalize {
  map {
    s/[_:]+$//g;
    s/^[_:]+//g;
    lc($_);
  } @_;
}


