package Jabbot::Messages;
use Jabbot::Base -Base;
use List::Util qw(shuffle);

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
    my $ret;
    if (@{$self->must_say}) {
        my $text = join(" ", map { $_->text } @{$self->must_say});
        $ret = $self->must_say->[0];
        $ret->text($text);
    }
    elsif(@{$self->normal}) {
        $ret = (shuffle @{$self->normal})[0];
    }
    else {
        $ret = $self->hub->message->new;
    }

    $self->must_say([]);
    $self->normal([]);
    return $ret;
}


