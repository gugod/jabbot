package Jabbot::Back::CPANTaiwan;
use common::sense;
use parent 'Jabbot::Component';
use JSON qw(decode_json encode_json);
use AnyEvent;
use AnyEvent::MP;
use AnyEvent::MP::Global;
use AnyEvent::HTTP;
use URI;
use XML::RSS;
use Acme::CPANAuthors;
use Encode qw(encode_utf8);

sub publish_message {
    my %args = @_;
    my $irc = grp_get "jabbot-irc";
    snd $_ , post => \%args for @$irc;
}

sub run {
    configure profile => "jabbot-cpantw";
    my $taiwan_authors     = Acme::CPANAuthors->new('Taiwanese');
    my $config             = Jabbot->config->{cpantw};

    die 'config is not defined.' unless $config;

    my %publish_to = map { $_ => [ split /:/ ] } @{ $config->{publish_to} };

    die 'network or channel is required' unless %publish_to;

    my %displayed = ();

    my $uri                = URI->new( $config->{url} || 'http://frepan.org/feed/index.rss' );
    my $w = AnyEvent->timer(after => 1,  interval => 10, cb => sub {
        http_get $uri, sub { 
            my ($content,$headers) = @_;
            my $rss = XML::RSS->new;
            $rss->parse($content);

            # for testing:
            # my @items = @{ $rss->{items} };

            my @items = grep { defined($taiwan_authors->{ $_->{dc}->{creator} }) } @{ $rss->{items} };
            for my $item (@items) {
                # Item structure:
                #   Title: Net-Netfilter-NetFlow-1.113260 OLIVER
                #   Creator: OLIVER
                #   Link: http://beta.metacpan.org/release/OLIVER/Net-Netfilter-NetFlow-1.113260
                my $title = $item->{title};
                my $author_id = $item->{dc}->{creator};
                my $link = $item->{link};

                next if $displayed{ $link };
                $displayed{ $link } = 1;

                my $msg = sprintf('%s by %s', $link , $author_id);
                for my $to ( values %publish_to ) {
                    my ($network,$channel) = @$to;
                    print "$network:$channel => $msg\n";
                    publish_message 
                            body    => $msg, 
                            command => 'NOTICE',
                            network => $network, 
                            channel => $channel;
                }
            }
        };
    });

    __PACKAGE__->daemonize;
}

1;
