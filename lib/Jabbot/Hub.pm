package Jabbot::Hub;
use Spoon::Hub -Base;

sub process {
    $self->preload;
    my $action = $self->action;
    die "No plugin for action '$action'"
      unless defined $self->registry->lookup->action->{$action};
    my ($class_id, $method) = 
      @{$self->registry->lookup->action->{$action}};
    $method ||= $action;
    return $self->$class_id->$method;
}
