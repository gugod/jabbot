package Jabbot::Hub;
use Spoon::Hub -Base;
use List::Util qw(shuffle reduce);

sub process {
    $self->preload;
    my $msg = shift;
    my $reply = reduce {
        $a->priority > $b->priority ? $a : $b
    } map {
        $self->$_->process($self->hub->message->new(text => $msg))
    } shuffle($self->all_plugin_ids);
    $reply->text;
}

sub all_plugin_ids {
    map {$_->{id}} @{$self->registry->lookup->plugins};
}
