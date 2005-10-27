package Jabbot::FrontEnd::AIM;
use Jabbot::FrontEnd -base;
use Net::OSCAR qw(:standard);
use HTML::Strip;
use Encode qw(encode decode from_to);
use YAML;

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
    my $msg_text = $hs->parse( $message );
    print STDERR "==> $sender: $msg_text\n ==== $message\n";

     my $reply = $self->hub->process (
	  $self->hub->message->new (
	   text => $msg_text,
	   from => $sender,
	   channel => $sender,
	   to => $self->hub->config->{aim_username}
	  ));
    my $reply_text = $reply->text;
    if(length($reply_text)) {
	$reply_text = encode('utf8',$reply_text);
	$aim->send_im($sender,$reply_text);
    }
}

sub on_error {
    my ($aim, $conn, $error, $description, $fatal) = @_;
    print STDERR "Error: $description\n";
}

1;
