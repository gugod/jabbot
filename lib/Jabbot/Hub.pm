package Jabbot::Hub;
use Spoon::Hub -Base;
use List::Util qw(shuffle);

sub process {
    my $msg = shift;
    $self->preload;
    my @reply = map {
        $self->$_->process($msg);
    } $self->all_plugin_ids;
    return (shuffle @reply)[0];
}

sub all_plugin_ids {
    map {$_->{id}} @{$self->registry->lookup->plugins};
}
