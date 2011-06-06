package Jabbot::RemoteCore;
use common::sense;
use Object::Tiny;
use HTTP::Lite;
use JSON qw(from_json);

use AnyEvent;
use AnyEvent::MP;
use AnyEvent::MP::Global;

configure;

sub DESTROY {}

our $AUTOLOAD;

sub AUTOLOAD {
    my ($self, %args) = @_;

    my $name = $AUTOLOAD;
    $name =~ s/.*://;

    print "XDXDXD $name %args\n";

    my $ports = grp_get "jabbot_core" or return;

    print "XDXDXD 123123\n";

    for (@$ports) {
        snd $_, action => { name => $name, args => \%args }
    }

    # my $core_server = "http://localhost:15000";
    # my $http = HTTP::Lite->new;
    # $http->prepare_post(\%args);
    # my $status = $http->request("${core_server}/${name}");
    # if ($status == 200) {
    #     my $body = $http->body;
    #     if ($body ne "OK") {
    #         my $response = from_json($http->body);
    #         return $response->{$name};
    #     }
    # }

    return $self;
}

1;

=head1 SYNOPSIS

plackup -s Twiggy -l :15000 -Ilib -MJabbot::Core       -e '\&Jabbot::Core::app' &
plackup -s Twiggy -l :15001 -Ilib -MJabbot::Front::IRC -e "\&Jabbot::Front::IRC::app" &

perl -Ilib -MJabbot::RemoteCore -E 'Jabbot::RemoteCore->post(channel => "/irc/networks/freenode/channels/jabbot", text => "OHAI 1337")'

=cut
