package Jabbot::FrontEnd::CGI;

use Jabbot::FrontEnd -base;
use CGI::Minimal;
use Encode;
use YAML;

sub process {
    my $self = shift;
    my $cgi = CGI::Minimal->new;

    my $message_text = $cgi->param("s");

    if (!$message_text) {
        return $self->render_json({ noreply => 1 });
    }

    $message_text = Encode::decode_utf8($message_text);

    my $message = $self->hub->message->new(
        from => "CGI",
        channel => "CGI",
        to => $self->hub->config->nick,
        text => $message_text
    );

    $self->hub->pre_process;
    my $reply = $self->hub->process($message);
    $self->hub->post_process;

    return $self->render_json({
        reply => $reply->to_hash
    });
}

use JSON;
sub render_json {
    my ($self, $var) = @_;

    my $json = JSON->new;
    $json->convert_blessed(1);

    print "Content-Type: tejxt/x-json\n\n";
    print $json->encode($var);
}

1;
