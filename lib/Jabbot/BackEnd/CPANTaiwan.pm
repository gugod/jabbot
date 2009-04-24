package Jabbot::BackEnd::CPANTaiwan;
use strict;
use Jabbot::BackEnd -base;
use POE;
use POE::Component::RSSAggregator;
use POE::Component::AtomAggregator;

use POE::Component::IKC::ClientLite;
use WWW::Shorten 'TinyURL';
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
        tmpdir   => '/tmp',     # optional caching
    );

    my %feeds = %{$self->config->{cpanfeeds}};
    my @feeds = map { { name => $_ , %{ $feeds{$_} } } } keys %feeds;
    map { for my $k ( qw(publish_to shortenurl appendurl) ) {  delete $_->{$k}  }  } @feeds;
    delete $_->{type},$kernel->post( 'rssagg', 'add_feed', $_ )
        for grep { $_->{type} eq 'rss' } @feeds;
    delete $_->{type},$kernel->post( 'atomagg', 'add_feed', $_ )
        for grep { $_->{type} eq 'atom' } @feeds;
}

sub handle_feed {
    my ($kernel,$feed) = ($_[KERNEL], $_[ARG1]->[0]);

    warn "handle_feed";
    my $remote = create_ikc_client(
        port => $self->config->{irc}{frontend_port},
        serialiser => 'FreezeThaw'
       ) or die POE::Component::IKC::ClientLite::error();

    use Acme::CPANAuthors;
    my $taiwan_authors = Acme::CPANAuthors->new('Taiwanese');

    # XXX: let user can register his/her name from irc

    my $feed_name = $feed->name;
    for my $headline (reverse $feed->late_breaking_news) {
        my $config = $self->config->{cpanfeeds}{$feed_name};

        # XXX: may be any country not only taiwanese.
        # filter modules by cpan authors here
        my $channels = $self->config->{cpanfeeds}{$feed_name}{publish_to};
        next unless $channels;

        my ( $mod_name , $link )
            = $headline->can("headline")
                ? ( $headline->headline, $headline->url )
                : $headline->can("title")
                    ? ( $headline->title, $headline->link )
                    : ();

        my ($author_id) = $link =~ m{http://search.cpan.org/~(\w+)/}i ;
        next unless( defined $taiwan_authors->{ uc( $author_id ) } );

        my $text = "$mod_name by $author_id++ ( @{[  $taiwan_authors->{ uc( $author_id ) }  ]} )";

        $text = "${feed_name}: " . $text;

        if ($config->{appendurl}) {
            my $url = $config->{shorturl} ? eval 'makeashorterlink($link)' : $link;
            $text .= " : $url";
        }

        my $utf8_text = ($config->{type} eq 'rss') ? Encode::encode('utf8',$text) : $text;

        for(@$channels) {
            my($network,$channel) = split(/:/,$_);

            # check if it's in taiwan authors
            say "Posting to $network/$channel: $utf8_text";
            $remote->post("irc_frontend_${network}/message",
                        {channel => $channel,
                        network => $network,
                        text => $utf8_text})
                or die $remote->error;

            # not to flush too faster
            sleep 1;
        }
    }
}

1;
