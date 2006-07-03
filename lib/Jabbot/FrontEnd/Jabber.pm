package Jabbot::FrontEnd::Jabber;
use strict;
use warnings;

use Jabbot::FrontEnd -base;

use Net::XMPP;

use Encode qw(encode decode from_to);

my $self;

sub process {
    $self = shift;
    my $config = $self->hub->config;
    my $jabber_conf = {
                       hostname => $config->{jabber_server},
                       port => 5222,
                       username => $config->{jabber_username},
                       password => $config->{jabber_password},
                       tls => 0,
                      };
    my $client = $self->init_client($jabber_conf);
    $client->SetCallBacks(message => \&on_message);
    while (defined($client->Process())) {}
    $client->Disconnect();
}

sub init_client {
    my $self   = shift;
    my $config = shift;
    my $client = new Net::XMPP::Client();
    $self->{client} = $client;

    my $status = $client->Connect(
                                  hostname => $config->{hostname},
                                  port => $config->{port},
                                 );

    if (!defined($status)) {
        die"Jabber server down"
    }

    my @result = $client->AuthSend(
                                   username => $config->{username},
                                   password => $config->{password},
                                   tls => $config->{tls},
                                   resource => 'Jabbot'
                                  );

    die "Auth error" if ($result[0] ne "ok");

    $client->RosterGet();
    $client->PresenceSend();
    return $client
}

sub on_message {
    my $sid = shift;
    my $message = shift;
    my $type = $message->GetType();
    my $fromJID = $message->GetFrom("jid");
    my $from = $fromJID->GetUserID();
    my $resource = $fromJID->GetResource();
    my $subject = $message->GetSubject();
    my $body = $message->GetBody();

    shift; # my $self = shift;
    my $msg = $self->hub->message->new (
         text => $body,
         from => $fromJID,
         to   => $self->hub->config->nick,
         channel => '__jabber'
        );
    my $reply = $self->hub->process($msg);

    print "<< $body\n";
    print ">> " . $reply->text . "\n";

    $self->{client}->MessageSend(
                         Body => $reply->text,
                         To => $fromJID,
                         From => $message->GetTo("jid"),
                         type => 'chat'
                        );

}

1;
