package Jabbot::BackEnd::CheatConsole;
use Jabbot::BackEnd -Base;
use Term::ReadLine;

sub process {
    no warnings 'once';
    require POE::Component::IKC::ClientLite;
    my $remote = POE::Component::IKC::ClientLite::create_ikc_client(
        port => $self->config->irc_daemon_port,
        name => "CheatConsole$$",
        timeout => 5,
    ) or die $POE::Component::IKC::ClientLite::error;

    my $term = new Term::ReadLine 'Cheat Console';
    my $IN = $term->IN;
    binmode($IN,":utf8");
    while(defined ($_ = $term->readline('cheat> '))) {
        my ($channel,$text) = split(/[,\s]+/,$_,2);
        next unless defined($text);
        $remote->post('frontend_irc/update',
                      {channel => $channel,
                       text =>$text});
        $term->addhistory($_)
    }
}
