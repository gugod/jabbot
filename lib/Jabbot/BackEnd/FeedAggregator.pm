package Jabbot::BackEnd::FeedAggregator;
use Jabbot::BackEnd -Base;

sub init {
    $self->use_class('message_database');
}

sub process {
    my $i = 0;
    while($i < 100) {
        sleep(1);
        my $msg = $self->message->new(text => "crap $i",must_say=>1);
        $self->message_database->append($msg);
        $i++;
    }
}

