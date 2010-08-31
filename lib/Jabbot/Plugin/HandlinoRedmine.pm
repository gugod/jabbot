package Jabbot::Plugin::HandlinoRedmine;
use parent 'Jabbot::Plugin';
use common::sense;
use self;

sub can_answer {
    my ($text) = @args;
    if ($text =~ m/#([1-9][0-9]*)\b/) {
        $self->{issue_number} = $1;
        return 1;
    }
    return 0;
}

sub answer {
    my ($text) = @args;

    return {
        content => "http://redmine.handlino.com/issues/" . $self->{issue_number},
        confidence => 1
    };
}

1;
