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

sub to_hash {
    return {
        text => $self->text,
        must_say => $self->must_say,
        to => $self->to,
        from => $self->from,
        channel => $self->channel,
    };
}
