package Jabbot::FrontEnd::Jabber;
use strict;
use warnings;
use utf8;

use Jabbot::FrontEnd -base;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

use Net::Jabber::Bot;

my $self;
my $bot;

sub process {
    $self = shift;
    my $config = $self->hub->config->{jabber};

    $bot = Net::Jabber::Bot->new({
        server                  => $config->{server},
        gtalk                   => $config->{gtalk},
        conference_server       => $config->{server},
        port                    => $config->{port},
        username                => $config->{username},
        password                => $config->{password},
        alias                   => $config->{username},
        message_callback        => \&bot_message,
        background_activity     => \&background_checks,
        loop_sleep_time         => 15,
        process_timeout         => 5,
        ignore_server_messages  => 0,
        ignore_self_messages    => 0,
        out_messages_per_second => 40,
        max_message_size        => 1000,
        max_messages_per_hour   => 100
    }) or die "WTF\n";

    $bot->SendPersonalMessage( 'gugodliu', "How are you.");

    $bot->Start();
}

use Encode;
use YAML;

sub bot_message {
    my %bot_message_hash = @_;

    my $user    = $bot_message_hash{reply_to};
    my $message = $bot_message_hash{body};

    print "IN: $message\n";
    my $reply = $self->hub->process(
        $self->hub->message->new(
            text => $message,
            from => $user,
            channel => 'jabber',
            to => $self->hub->config->nick,
        )
    );

    my $reply_text = $reply->text || "";
    print "REPLY: $reply_text\n";

    if(length($reply_text)) {
        $bot->SendPersonalMessage( $user, Encode::encode('utf8', $reply_text) );
    }
}

sub background_checks {
    print "!!! background_checks\n";
}

1;
