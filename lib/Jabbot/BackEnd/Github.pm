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



sub committer_name {
    my $commit = shift;
    my $name = $commit->{author}{name};
    unless ( $name ) {
        $name = $commit->{author}{email};
        $name =~ s/@.+$//;
    }
    return $name;
}

=head2 short_url

make shorter url

=cut

sub short_url {
    my $url = shift;
    eval {
        $url = makeashorterlink($url) if $url;
    };
    if( $@ ) {
        warn 'shortenlink fail:' . $@;
        return "";
    }
    return $url;
}

=head2 build_digest_commit_message hashref:payload

=cut

sub build_digest_commit_message {
    my $payload = shift;
    my $repo = $payload->{repository};
    my $commits = $payload->{commits};

    my $first = $commits->[0];
    my $num = scalar @$commits;
    my $committer = committer_name $first ;
    my $url = short_url $repo{url};
    return sprintf( "%s pushed to %s , %d commits. ( %s ) ",
        $committer, $repo{name}, $num, $url );
}

=head2 build_commit_message

=cut

sub build_commit_message {
    my $repo = shift;
    my $commit = shift;

    my $committer = committer_name $commit ;
    my $url = short_url $commit->{url};

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

                if ( scalar( @{ $info->{commits} } ) > 5  ) {
                    my $text = build_digest_commit_message( $payload );
                    $remote->post("irc_frontend_${network}/message", { 
                            channel => $channel,
                            text => $text,
                            network => $network });
                }
                else {
                    for my $commit (@{ $info->{commits} || [] }) {
                        my $text = build_commit_message( $repo, $commit );
                        $remote->post("irc_frontend_${network}/message", { 
                                channel => $channel,
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

    
