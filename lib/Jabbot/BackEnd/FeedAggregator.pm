package Jabbot::BackEnd::FeedAggregator;
use strict;
use Jabbot::BackEnd -base;
use POE;
use POE::Component::RSSAggregator;

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
        my $name = $_;
        $name =~ s{/}{.}g;
        {
            url => $_,
            delay => 600,
            name => $name,
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
    no warnings 'once'; # i use package variables below
    require POE::Component::IKC::ClientLite;
    my $remote = POE::Component::IKC::ClientLite::create_ikc_client(
        port => $self->config->irc_daemon_port,
        name => "FeedAggregator$$",
        timeout => 5,
    ) or die $POE::Component::IKC::ClientLite::error;
    for my $headline ($feed->late_breaking_news) {
        $remote->post('frontend_irc/update', {channel => '-ALL',
                                              text => $headline->headline});
    }
}

1;
