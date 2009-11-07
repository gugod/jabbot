package Jabbot::BackEnd::Github;
use strict;

use Jabbot::BackEnd -base;

const class_id => 'github';

use POE;
use POE::Component::Server::HTTP;
use POE::Component::IKC::ClientLite;
use CGI::Simple;

use HTTP::Status;
use JSON::XS;
use WWW::Shorten '0rz';

my $self;

sub process {
    $self = shift;
    POE::Session->create(
        inline_states => {
            _start      => \&init_session,
        }
    );
    $poe_kernel->run();

}



sub build_digest_commit_message {
    my $repo = shift;
    my $commits = shift;





}

=head2 build_commit_message

=cut

sub build_commit_message {
    my $repo = shift;
    my $commit = shift;
    my $committer = $commit->{author}{email};
    $committer =~ s/@.+$//;

    my $url = $commit->{url};
    eval {
        $url = makeashorterlink($url) if $url;
    };
    if( $@ ) {
        warn 'shortenlink fail:' . $@;
    }
    return sprintf("%s | %s++ | %s - %s " , 
            $repo , 
            $committer, 
            $commit->{message},
            $url );
}






=head2 init_session

github payload document:

L<http://help.github.com/post-receive-hooks/>

=cut

sub init_session {
    my ($kernel) = ($_[KERNEL]);

    my $remote = POE::Component::IKC::ClientLite::create_ikc_client(
        port => $self->config->{irc}{frontend_port},
        name => "Github$$",
        serialiser => 'FreezeThaw'
    ) or die $POE::Component::IKC::ClientLite::error;

    my $server = POE::Component::Server::HTTP->new(
        Port => $self->config->{github}{port},
        ContentHandler => {
            '/' => sub {
                my ($request, $response) = @_;

                my $p = CGI::Simple->new( $request->content );
                my $network = $p->param('network');
                my $channel = $p->param('channel');
                my $payload = $p->param('payload');
                my $info    = decode_json($payload);
                my $repo    = $info->{repository}{name};

                if ( scalar( @{ $info->{commits} } ) > 8  ) {
                    my $text = build_digest_commit_message( $repo, $info->{commits} );

                }
                else {
                    for my $commit (@{ $info->{commits} || [] }) {

                        my $text = build_commit_message( $repo, $commit );

                        # warn "[$network/$channel] $text\n";

                        $remote->post("irc_frontend_${network}/message",
                            { channel => $channel,
                                text =>$text,
                                network => $network });
                    }
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

    print STDERR "Github Backend Started, available at port " . $self->config->{github}{port} . "\n";
}



1;

    
