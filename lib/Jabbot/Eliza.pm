package Jabbot::Eliza;
use Jabbot::Plugin -Base;
use Chatbot::Eliza;

const class_id => 'eliza';

field chatterbot => {},
    -init => 'Chatbot::Eliza->new()';

sub process {
    return $self->message->new(
        text => $self->chatterbot->transform(shift->text));
}

