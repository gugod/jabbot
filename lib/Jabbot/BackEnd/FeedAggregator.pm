package Jabbot::FeedAggregate;
use Jabbot::BackEnd -Base;

sub init {
    $self->use_class('messages');
    $self->use_class('message');
}

sub process {
    my $i = 0;
    while($i < 100) {
        sleep(1);
        my $msg = $self->message->new(text => "crap $i",must_say=>1);
        $self->messages->append($msg);
        $i++;
    }
}

