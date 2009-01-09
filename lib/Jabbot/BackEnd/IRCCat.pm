package Jabbot::BackEnd::IRCCat;
use Jabbot::BackEnd -Base;
use Term::ReadLine;

sub process {
    no warnings 'once';
    require POE::Component::IKC::ClientLite;
    my $remote = POE::Component::IKC::ClientLite::create_ikc_client(
        port => $self->config->{irc}{frontend_port},
        name => "IRCCat$$",
        timeout => 5,
    ) or die $POE::Component::IKC::ClientLite::error;

    binmode(STDIN,":utf8");
    while(<STDIN>) {
        # freenode #jabbot Hello, world.
        my ($network, $channel, $text) = split(/ /, $_, 3);
        next unless defined($text) && defined($channel);

        $channel =~ s/^#//;

        for my $n (@{$self->config->{irc}{networks}}) {
            next unless $n eq $network;
            $remote->post("irc_frontend_${network}/message",
                          {channel => $channel,
                           text =>$text,
                           network => $network });
        }  
    }
}
