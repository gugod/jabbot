package Jabbot::FrontEnd::YahooMessenger;
use strict;
use Jabbot::FrontEnd -base;
use Net::YahooMessenger;
my $self;

sub process {
    $self = shift;
    my $config = $self->hub->config;

    my $yahoo = Net::YahooMessenger->new
	(
	 id => $config->{yahoo_username},
	 password => $config->{yahoo_password},
	 hostname => 'scs.msg.yahoo.com',
	 port   => 5050,
	);
    $yahoo->set_event_handler(new Jabbot::FrontEnd::YahooMessenger::EventHandler);
    $yahoo->login or die "Can't login Yahoo!Messenger";
    $yahoo->start;
}

package Jabbot::FrontEnd::YahooMessenger::EventHandler;
use base 'Net::YahooMessenger::EventHandler';
use strict;

sub ChangeState {}
sub GoesOffline {}
sub GoesOnline {}
sub UnImplementEvent {}

sub ReceiveMessage {
    my $self = shift;
    my $event = shift;
    printf "%s: %s\n", $event->from, $event->body;
}






1;
