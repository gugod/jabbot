package Jabbot::FrontEnd::Twitter;
use strict;
use warnings;
use Jabbot::FrontEnd -base;
use Encode qw(encode_utf8 encode decode from_to);
use YAML;
use Net::Twitter;

sub process {
    my $self = shift;
    io("var/run/twitter_state.yml")->assert->touch;

    $self->read_public_timeline;
}


sub read_public_timeline {
    my $self = shift;
    my $config = $self->hub->config;

    my $state = YAML::Load(io("var/run/twitter_state.yml")->assert->utf8->all);

    my $twit = Net::Twitter->new(
        useranme => $config->{twitter_username},
        password => $config->{twitter_password}
    );

    my $status_id = $state->{last_read_public_timeline_status_id} ||= 1;
    for my $entry (@{ $twit->public_timeline($status_id) }) {

        my $reply = $self->hub->process(
            $self->hub->message->new(
                text => $entry->{text},
                channel => "twitter",
                from => $entry->{user}{screen_name},
                to => "",
            )
        );


        $state->{last_read_public_timeline_status_id} = $entry->{id};
        print STDERR encode_utf8("$entry->{user}{screen_name}: $entry->{text}\n");
        # Do nothing with $reply;
    }

    io("var/run/twitter_state.yml")->assert->utf8->print(
        YAML::Dump($state)
    );
}



1;
