package Jabbot::BackEnd::FeedAggregator;
use Jabbot::BackEnd -Base;

sub process {
    no warnings 'once'; # i use package variables below
    require POE::Component::IKC::ClientLite;
    my $remote = POE::Component::IKC::ClientLite::create_ikc_client(
        port => $self->config->irc_daemon_port,
        name => "Kwiki$$",
        timeout => 5,
    ) or die $POE::Component::IKC::ClientLite::error;
    $remote->post('frontend_irc/update', 'trasite');
}
