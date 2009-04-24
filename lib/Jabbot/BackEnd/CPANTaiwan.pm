package Jabbot::BackEnd::CPANTaiwan;
use strict;
use Jabbot::BackEnd -base;
use POE;
use POE::Component::RSSAggregator;
use POE::Component::AtomAggregator;

use POE::Component::IKC::ClientLite;
use WWW::Shorten 'tinyurl';
use Encode;

my $self;

sub process {
    $self = shift;
    POE::Session->create(
        inline_states => {
            _start      => \&init_session,
            handle_feed => \&handle_feed,
        }
       );
    $poe_kernel->run();
}

sub init_session {
    my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];
    $heap->{rssagg} = POE::Component::RSSAggregator->new(
        alias    => 'rssagg',
        debug    => 1,
        callback => $session->postback("handle_feed"),
        # tmpdir   => '/tmp',     # optional caching
    );

    my %feeds = %{$self->config->{cpanfeeds}};
    my @rss_feeds = map { { name => $_ , url => $feeds{ $_ }->{url} } } 
                    grep { $feeds{ $_ }->{type} eq 'rss' }  keys %feeds;
    my @atom_feeds = map { { name => $_ , url => $feeds{ $_ }->{url} } } 
                    grep { $feeds{ $_ }->{type} eq 'rss' }  keys %feeds;
    $kernel->post('rssagg','add_feed',$_) for @rss_feeds;
    $kernel->post('atomagg','add_feed',$_) for @atom_feeds;
}

sub handle_feed {
    my ($kernel,$feed) = ($_[KERNEL], $_[ARG1]->[0]);

    warn "handle_feed";
    my $remote = create_ikc_client(
        port => $self->config->{irc}{frontend_port},
        serialiser => 'FreezeThaw'
       ) or die POE::Component::IKC::ClientLite::error();

    use Acme::CPANAuthors;
    my $authors = Acme::CPANAuthors->new('Taiwanese');

    my $feed_name = $feed->name;
    for my $headline (reverse $feed->late_breaking_news) {
        my $config = $self->config->{cpanfeeds}{$feed_name};

        # XXX: may be any country not only taiwanese.
        # filter modules by cpan authors here
        my $channels = $self->config->{cpanfeeds}{$feed_name}{publish_to};
        next unless $channels;

        my ( $text, $link )
            = $headline->can("headline")
                ? ( $headline->headline, $headline->url )
                : $headline->can("title")
                    ? ( $headline->title, $headline->link )
                    : ();

        my ($author_id) = $link =~ m{http://search.cpan.org/~(\w+)/}i;

        if ($headline->can('author')) {
            my $author = $headline->author;
            if ($author) {
                $text = "(@{[ $author->name ]}) $text";
            }
        }

        $text = "${feed_name} - " . $text;
        if ($config->{appendurl}) {
            my $url = $config->{shorturl} ? eval 'makeashorterlink($link)' : $link;
            $text .= " $url";
        }

        my $utf8_text = ($config->{type} eq 'rss') ? Encode::encode('utf8',$text) : $text;

        for(@$channels) {
            my($network,$channel) = split(/:/,$_);
            say "Posting to $network/$channel: $utf8_text";

            $remote->post("irc_frontend_${network}/message",
                          {channel => $channel,
                           network => $network,
                           text => $utf8_text})
                or die $remote->error;
        }
    }
}

1;
