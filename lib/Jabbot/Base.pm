package Jabbot::Base;
use Spoon::Base -Base;
our $VERSION = '3.00_01';

sub init {
    $self->use_class('config');
}
