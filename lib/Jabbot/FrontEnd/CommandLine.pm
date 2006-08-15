package Jabbot::FrontEnd::CommandLine;
use Jabbot::FrontEnd -Base;
use Encode;
use YAML;
sub process {
	my $hub = $self->hub;
	my $text = join(" ", @_);
	binmode(STDOUT,':utf8');
	$hub->pre_process;
	my $reply = $hub->process(
			$self->hub->message->new(
				text => Encode::decode_utf8( $text ),
				from => $ENV{USER},
				channel => 'commandline',
				));
	print "=> ",$reply->text,"\n";
	$hub->post_process;
}

