package Jabbot::Eliza;
use Jabbot::Plugin -Base;
use Chatbot::Eliza;

const class_id => 'eliza';

field chatterbot => {}.
    -init => 'new Chatbot::Eliza';

sub process {
    $self->chatterbot->transform( shift )
}

