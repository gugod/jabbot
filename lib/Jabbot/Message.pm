package Jabbot::Message;
use Jabbot::Base -Base;

field must_say => 0;
field text     => '';
field from     => '';
field to       => '';
field channel  => '';

sub me {
    $self->to eq $self->config->{nick}
}
