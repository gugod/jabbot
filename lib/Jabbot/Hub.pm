package Jabbot::Hub;
use Spoon::Hub -Base;
use List::Util qw(shuffle);

sub init {
    $self->use_class('messages');
    $self->use_class('message');
}

sub process {
    $self->preload;
    my $msg = shift;

    my @replies = grep {
        defined $_->text
    } map {
        $self->$_->process($self->message->new(text => $msg))
    } $self->all_plugin_ids;

    if(my @musts = grep {$_->must_say} @replies) {
        $self->messages->append($_) for @musts;
    } else {
        $self->messages->append((shuffle @replies)[0]);
    }

    my $reply = $self->messages->next;
    $reply->text;
}

sub all_plugin_ids {
    map {$_->{id}} @{$self->registry->lookup->plugins};
}
