package Jabbot::FrontEnd::AIM;
use Jabbot::FrontEnd -base;

use Net::AIM;
use YAML;

my $self;
sub process {
    $self = shift;
    my $config = $self->hub->config;
    my $aim = new Net::AIM;
    $aim->newconn(Screenname => $config->{aim_username},
		  Password   => $config->{aim_password})
	or die "Cannot connect to AIM";
    my $conn = $aim->getconn();
    $conn->set_handler('IM_IN', \&on_im);
    $conn->set_handler('ERROR', \&on_error);
    print "Logged on to AIM!\n";
    $aim->start;
}

sub on_im {
    my ($aim, $evt, $from, $to) = @_;
    my $args = $evt->args();
    ($from, my $friend, my $msg) = @$args;
    $msg =~ s/<(.|\n)+?>//g;
    print STDERR "==> $from $friend $msg\n";
}

sub on_error {
    my ($aim,$evt) = @_;
    my ($error, @stuff) = @{$evt->args()};
    my $errstr = $evt->trans($error);
    $errstr =~ s/\$(\d+)/$stuff[$1]/ge;
    print "ERROR: $errstr\n";
}


1;
