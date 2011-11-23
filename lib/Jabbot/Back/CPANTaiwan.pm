package Jabbot::Back::CPANTaiwan;
use warnings;
use strict;
use common::sense;
use JSON qw(decode_json encode_json);
use AnyEvent;
use AnyEvent::MP;
use AnyEvent::MP::Global;
use URI;
use AnyEvent::HTTP;
use XML::RSS;
use Acme::CPANAuthors;
use WWW::Shorten 'TinyURL';

sub publish_message {
    my %args = @_;
    my $irc = grp_get "jabbot-cpantw";
    snd $_ , post => { 
        network => $args{network},
        channel => $args{channel},
        body => $args{msg},
            } for @$irc;
}


sub run {
    configure profile => "jabbot-cpantw";
    my $taiwan_authors     = Acme::CPANAuthors->new('Taiwanese');
    my $config             = Jabbot->config->{cpanfeeds}->{'CPAN-Upload'};
    my ($network,$channel) = split /:/,$config->{publish_to};
    my $url                = $config->{url};
    my $w = AnyEvent->timer(after => 0,  interval => 100, cb => sub {
        my $uri = URI->new('http://frepan.org/feed/index.rss');
        http_get $uri, sub { 
            my ($content,$headers) = @_;
            my $rss = new XML::RSS;
            $rss->parse($content);
            my @items = grep { defined($taiwan_authors->{ $_->{dc}->{creator} }) } @{ $rss->{items} };
            for my $item (@items) {
                # Item structure:
                #   Title: Net-Netfilter-NetFlow-1.113260 OLIVER
                #   Creator: OLIVER
                #   Link: http://beta.metacpan.org/release/OLIVER/Net-Netfilter-NetFlow-1.113260
                my $title = $item->{title};
                my $author_id = $item->{dc}->{creator};
                my $link = $item->{link};
                warn $link;
                publish_message msg => $link, network => $network, channel => $channel;
            }
        };
    });
    AE::cv->recv;
}

1;
