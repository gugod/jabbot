package Jabbot::Backend::Github;
use Jabbot::BackEnd -Base;
use POE;
use POE::Component::IKC::ClientLite;

use POE::Component::Server::HTTP;
use HTTP::Status;
use JSON::XS;

sub process {
    my $remote = POE::Component::IKC::ClientLite::create_ikc_client(
        port => $self->config->irc_frontend_port,
        name => "GithubBackend$$",
        timeout => 5,
    ) or die $POE::Component::IKC::ClientLite::error;

    my $server = POE::Component::Server::HTTP->new(
        Port => 8000,
        ContentHandler => {
            '/' => sub {
                my ($request, $response) = @_;

                my $p = CGI::Simple->new( $request->content );
                my $network = $p->param('network');
                my $channel = '#' . $p->param('name');
                my $payload = $p->param('payload');
                my $info    = decode_json($payload);

                my $repo    = $info->{repository}{name};

                for my $commit (@{ $info->{commits} || [] }) {

                    my $committer = $commit->{author}{email};
                    $committer =~ s/@.+$//;

                    my $text = "$repo | ${committer}++ | $commit->{message} - $commit->{url}";

                    $remote->post("irc_frontend_${network}/message",
                          {channel => $channel,
                           text =>$text,
                           network => $network });
                }
                
                $response->code(RC_OK);
                $response->content("OK");
                return RC_OK;
            }
        },
        Headers => {
            Server => "Jabbot Github Backend Server"
        }
    );
}



1;

    
