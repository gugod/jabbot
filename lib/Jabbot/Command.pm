package Jabbot::Command;
use Spoon::Command -Base;

sub handle_update {
    chdir io->dir(shift || '.')->assert->open . '';
    die "Can't update non Jabbot directory!\n" unless -d 'plugin';
    $self->create_registry;
    $self->hub->registry->load;
    $self->install($_) for $self->all_class_ids;
    $self->set_permissions;
}
