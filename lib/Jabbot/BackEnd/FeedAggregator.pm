package Jabbot::BackEnd::FeedAggregator;
use strict;
use Jabbot::BackEnd -base;
use POE;
use POE::Component::RSSAggregator;
use POE::Component::AtomAggregator;

use POE::Component::IKC::ClientLite;
use WWW::Shorten 'isgd';
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
        tmpdir   => Jabbot->root . '/var/run',
        init_headlines_seen => 1,
        headline_as_id => 1,
    );

    $heap->{atomagg} = POE::Component::AtomAggregator->new(
        alias    => 'atomagg',
        debug    => 1,
        callback => $session->postback("handle_feed"),
        tmpdir   => Jabbot->root . '/var/run',
        init_headlines_seen => 1,
        headline_as_id => 1,
    );

    my %feeds = %{$self->config->{feeds}};
    my @feeds = map { { name => $_, %{$feeds{$_}} } } keys %feeds;
    $kernel->post( 'rssagg', 'add_feed', $_ )
        for grep { $_->{type} eq 'rss' } @feeds;
    $kernel->post( 'atomagg', 'add_feed', $_ )
        for grep { $_->{type} eq 'atom' } @feeds;
}

sub handle_feed {
    my ($kernel,$feed) = ($_[KERNEL], $_[ARG1]->[0]);
    my $remote = create_ikc_client(
        port => $self->config->{irc}{frontend_port},
        serialiser => 'FreezeThaw'
       ) or die POE::Component::IKC::ClientLite::error();

    my $feed_name = $feed->name;
    for my $headline (reverse $feed->late_breaking_news) {
        my $config = $self->config->{feeds}{$feed_name};

        my $channels = $self->config->{feeds}{$feed_name}{publish_to};
        next unless $channels;

        my ( $text, $link )
            = $headline->can("headline")
            ? ( $headline->headline, $headline->url )
            : $headline->can("title")
            ? ( $headline->title, $headline->link )
            : ();

        if ($config->{showAuthor}) {
            if ($headline->can('author')) {
                my $author = $headline->author;
                if ($author) {
                    $text = "(@{[ $author->name ]}) $text";
                }
            }
        }

        $text = "${feed_name} | " . $text;
        if ($config->{appendurl}) {
            # for ATOM $link is an object of XML::Atom::Link
            $link = $link->href if( ref( $link )  eq 'XML::Atom::Link' );

            my $url = $config->{shorturl} ? makeashorterlink($link) : $link;
            $text .= " | $url";
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
