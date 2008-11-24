package Jabbot::FrontEnd::Stdio;
use Jabbot::FrontEnd -Base;
use utf8;

sub process {
    my $hub = $self->hub;

    binmode(STDIN, ":utf8");
    binmode(STDOUT, ":utf8");

    while(<STDIN>) {
        chomp;
        print "<= $_\n";
	$hub->pre_process;
	my $reply = $hub->process(
            $self->hub->message->new(
                to => $self->config->{nick},
                text => $_,
                from => $ENV{USER},
                channel => 'FrontEnd::Stdio',
            )
        );
	print "=> ",$reply->text,"\n";
	$hub->post_process;
    }
}

