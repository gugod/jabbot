package Jabbot::Front::IRC;
use 5.012;
use strict;
use utf8;
use parent 'Jabbot::Component';

use JSON qw(decode_json encode_json);
use Encode qw(encode_utf8 decode_utf8);
use Jabbot;
use Jabbot::RemoteCore;

use AnyEvent;
use AnyEvent::IRC::Client;

sub init_irc_client {
    my ($network) = @_;

    my @connection_args = (
        $network->{server},
        $network->{port} || 6667,
        { nick => $network->{nick} }
    );

    my $client = AnyEvent::IRC::Client->new;
    $client->reg_cb(
        registered => sub {
            my ($client) = @_;
            say STDERR "[IRC] Connected to $network->{server}.";

            for (@{$network->{channels}}) {
                my ($channel, $key) = ref($_) ? @$_ : ($_);
                $channel = "#${channel}" unless index($channel, "#") == 0;
                $client->send_srv('JOIN', $channel, $key);
            }

            $client->enable_ping(
                300,
                sub {
                    my ($conn) = @_;
                    say STDERR "Connection Timeout\n";
                    $conn->disconnect("Connection Timeout.");
                    $client->connect(@connection_args);
                }
            );
        },

        join => sub {
            my ($client, $nick, $channel, $is_myself) = @_;
            if ($is_myself) {
                say STDERR "[IRC] Joined $channel";
            }
        },

        publicmsg => sub {
            my ($client, $channel, $ircmsg) = @_;
            my $text = Encode::decode("utf8", $ircmsg->{params}[1]);
            my $nick = $client->nick;

            my $to_me = $text =~ s/^${nick}:\s+//;
            return unless $to_me;

            my $from_nick = AnyEvent::IRC::Util::prefix_nick($ircmsg->{prefix}) || "";
            return if $from_nick =~ /${nick}_*/;

            state $jabbot = Jabbot::RemoteCore->new();
            my $answer = $jabbot->answer(q => $text);
            my $reply_text = $answer->{body};
            $reply_text = Encode::encode_utf8($reply_text);
            $client->send_chan($channel, "PRIVMSG", $channel, "$from_nick: $reply_text");
        },

        error => sub {
            local $, = ", ";
            say STDERR "ERROR: @_";
        }
    );

    $client->connect(@connection_args);
    return $client;
}

sub run2 {
    my $IRC_CLIENTS = {};
    my $networks = Jabbot->config->{irc}{networks};
    for (keys %$networks) {
        $networks->{$_}{name} = $_;
        $networks->{$_}{nick} ||= (Jabbot->config->{nick} || "jabbot_$$");
        $IRC_CLIENTS->{$_} = init_irc_client($networks->{$_})
    }
}

sub run {
    __PACKAGE__->daemonize(
        sub {
            __PACKAGE__->run2
        }
    );
}

1;

=head1 SYNOPSIS

Launch the irc clients

    perl -MJabbot::Front::IRC -e "Jabbot::Front::IRC->run";

Post to the givent channel (auto-joined if not alreay joined):

    perl -MJabbot::Front::IRC -e 'Jabbot::Front::IRC->cat(@ARGV)' freenode '#jabbot' "Ni Hao";

Post a NOTICE to the givent channel.

    perl -MJabbot::Front::IRC -e 'Jabbot::Front::IRC->cat(@ARGV)' freenode '#jabbot' NOTICE "Ni Hao";

=cut
