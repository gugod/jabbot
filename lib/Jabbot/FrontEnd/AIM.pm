package Jabbot::FrontEnd::AIM;
use Jabbot::FrontEnd -base;
use Net::OSCAR qw(:standard);
use HTML::Strip;
use Encode qw(encode decode from_to);
use Encode::Guess qw/utf16-be iso-8859-1/;
use YAML;
use IO::All;

my $self;
my $hs;

sub process {
    $self = shift;
    my $config = $self->hub->config;
    my $aim = Net::OSCAR->new();

    $aim->set_callback_im_in(\&on_im);
    $aim->set_callback_error(\&on_error);

    $aim->signon($config->{aim_username}, $config->{aim_password})
	or die "Cannot connect to AIM";

    $hs = HTML::Strip->new();

    while(1) {
	$aim->do_one_loop();
    }
}

sub on_im {
    my($aim, $sender, $message, $is_away) = @_;

    my $enc = guess_encoding($message, qw(utf16-be iso-8859-1));
    ref($enc) or return;

    my $u_message = $enc->decode($message);

    my $msg_text = $self->html_strip( $u_message );

    print YAML::Dump(sender => $sender, message => $u_message, txt => $msg_text);

     my $reply = $self->hub->process (
	  $self->hub->message->new (
	   text => $msg_text,
	   from => $sender,
	   channel => $sender,
	   to => $self->hub->config->{aim_username}
	  ));
    my $reply_text = $reply->text;
    if(length($reply_text)) {
	my $u8_reply_text = encode('utf8', $reply_text);
	print STDERR "<== $u8_reply_text\n";
	if(grep {ord($_) > 127} split("",$reply_text)) {
	    my $u_reply_text = encode('utf16', $reply_text);
	    $aim->send_im($sender,$u_reply_text);
	} else {
	    $aim->send_im($sender,$reply_text);
	}
    }
}

sub on_error {
    my ($aim, $conn, $error, $description, $fatal) = @_;
    print STDERR "Error: $description\n";
}

sub html_strip {
    my ($self,$text) = @_;
    $text =~ s/<[^<]*>//g;
    return $text;
}

1;
