package Jabbot::RemoteCore;
use common::sense;
use HTTP::Lite;

sub new {
    my $class = shift;
    return bless {}, $class;
}

our $AUTOLOAD;
sub AUTOLOAD {
    my ($self, %args) = @_;

    my $name = $AUTOLOAD;
    $name =~ s/.*://;

    my $core_server = "http://localhost:15000";
    my $http = HTTP::Lite->new;
    $http->prepare_post(\%args);
    $http->request("${core_server}/${name}");
    return $self;
}

1;

=head1 SYNOPSIS

plackup -s Twiggy -l :15000 -Ilib -MJabbot::Core       -e '\&Jabbot::Core::app' &
plackup -s Twiggy -l :15001 -Ilib -MJabbot::Front::IRC -e "\&Jabbot::Front::IRC::app" &

perl -Ilib -MJabbot::RemoteCore -E 'Jabbot::RemoteCore->post(channel => "/irc/networks/freenode/channels/jabbot", text => "OHAI 1337")'

=cut
