package Jabbot::Plugin;
use Spoon::Plugin -Base;
our $VERSION = '0.01';

stub 'class_id';
const config_file => '';
const class_title_prefix => 'Jabbot';

sub new {
    return $self if ref $self;
    super;
}

sub init {
    $self->use_class('config');
    $self->config->add_file($self->config_file);
}
