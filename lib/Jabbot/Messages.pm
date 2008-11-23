package Jabbot::Messages;
use Jabbot::Base -Base;

field must_say => [];
field normal => [];

sub append {
    my $msg = shift; # a Jabbot::Message obj
    if($msg->must_say) {
        push @{$self->must_say},$msg;
    } else {
        push @{$self->normal},$msg;
    }
}

sub next {
    shift(@{$self->must_say}) || shift(@{$self->normal}) || $self->message->new;
}


