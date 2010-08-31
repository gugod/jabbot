package Jabbot::Plugin::HandlinoRedmine;
use parent 'Jabbot::Plugin';
use common::sense;
use self;

sub can_answer {
    my ($text, $message) = @args;
    return unless $message->{channel} eq '/networks/freenode/channels/handlino';

    if ($text =~ m/#([1-9][0-9]*)\b/) {
        $self->{issue_number} = $1;
        return 1;
    }
    return 0;
}

sub answer {
    my ($text, $message) = @args;
    return unless $self->{issue_number};
    return {
        content => "http://redmine.handlino.com/issues/" . $self->{issue_number},
        confidence => 1
    };
}

1;
