package Jabbot::BackEnd::FeedAggregator;
use strict;
use Jabbot::BackEnd -base;
use POE;
use POE::Component::RSSAggregator;
use POE::Component::IKC::ClientLite;
use WWW::Shorten '0rz';
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
    my @feeds = map {
        {
            url => $self->config->{"feeds_${_}_url"},
            delay => $self->config->{"feeds_${_}_delay"} || 600,
            name => $_,
        }
    } @{$self->config->{feeds}};

    my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];
    $heap->{rssagg} = POE::Component::RSSAggregator->new(
        alias    => 'rssagg',
        debug    => 1,
        callback => $session->postback("handle_feed"),
        tmpdir   => '/tmp',     # optional caching
       );
    $kernel->post('rssagg','add_feed',$_) for @feeds;
}

sub handle_feed {
    my ($kernel,$feed) = ($_[KERNEL], $_[ARG1]->[0]);
    my $remote = create_ikc_client(
        port => $self->config->{irc_frontend_port},
	serialiser => 'FreezeThaw'
       ) or die POE::Component::IKC::ClientLite::error();

    my $feed_name = $feed->name;
    for my $headline ($feed->late_breaking_news) {
        my $channels = $self->config->{"feeds_${feed_name}_channels"};
        my $headline_text = $headline->headline;
        my $text = "${feed_name} - " . $headline_text;

        if($self->config->{"feeds_${feed_name}_appendurl"}) {
            my $url = ($self->config->{"feeds_${feed_name}_shorturl"})?
                eval 'makeashorterlink($headline->url)':$headline->url;
            $text .= " $url";
        }

	my $utf8_text = Encode::encode('utf8',$text);
	next unless $channels;
        for(@$channels) {
            my($network,$channel) = split(/:/,$_);
            say "Posting to $network/$channel: $utf8_text";
            $remote->post("irc_frontend_${network}/message",
                          {channel => $channel,
                           name => $network,
                           text => $utf8_text})
                or die $remote->error;
        }
    }
}

1;
