package Jabbot::Back::Twitter;
use warnings;
use strict;
use parent qw(Jabbot::Back);
use AnyEvent::Twitter::Stream;
use AnyEvent;
use AnyEvent::MP;
use AnyEvent::MP::Global;
use AnyEvent::HTTP;
use AE;
use utf8;
use Encode qw(decode_utf8);

sub publish_message {
    my %args = @_;
    my $irc = grp_get "jabbot-irc";
    snd $_ , post => \%args for @$irc;
}

sub run {
    configure profile => "jabbot-twitter";
    my $config = Jabbot->config->{twitter};

    die 'config for twitter is required' unless $config;

    my $irc = grp_get "jabbot-irc";
    my %publish_to = map { $_ => [ split /:/ ] } @{ $config->{publish_to} };
    my $guard = AnyEvent::Twitter::Stream->new(
        username => $config->{username},
        password => $config->{password},
        method   => "filter",
        track    => ($config->{track} || "perl,jabbot"),
        on_tweet => sub { 
            my $tweet = shift;
            my $msg =  "$tweet->{user}{screen_name}: $tweet->{text}";
            for my $to ( values %publish_to ) {
                my ($network,$channel) = @$to;
                print "$network:$channel => $msg\n";
                publish_message 
                        body    => $msg, 
                        # command => 'NOTICE',
                        network => $network, 
                        channel => $channel;
            }
        },
    );
    AE::cv->recv;
}


1;
