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
    my $config             = Jabbot->config->{cpantw};

    die 'config is not defined.' unless $config;

    my %publish_to = map { split /:/ } @{ $config->{publish_to} };

    die 'network or channel is required' unless %publish_to;

    my $uri                = URI->new( $config->{url} || 'http://frepan.org/feed/index.rss' );
    my $w = AnyEvent->timer(after => 0,  interval => 10, cb => sub {
        http_get $uri, sub { 
            my ($content,$headers) = @_;
            my $rss = XML::RSS->new;
            $rss->parse($content);
            my @items = @{ $rss->{items} };
            # my @items = grep { defined($taiwan_authors->{ $_->{dc}->{creator} }) } @{ $rss->{items} };
            for my $item (@items) {
                # Item structure:
                #   Title: Net-Netfilter-NetFlow-1.113260 OLIVER
                #   Creator: OLIVER
                #   Link: http://beta.metacpan.org/release/OLIVER/Net-Netfilter-NetFlow-1.113260
                my $title = $item->{title};
                my $author_id = $item->{dc}->{creator};
                my $link = $item->{link};
                warn $link;
                while( my ($network,$channel) = each %publish_to ) {
                    publish_message 
                            msg => $link, 
                            network => $network, 
                            channel => $channel;
                }
            }
        };
    });
    AE::cv->recv;
}

1;
