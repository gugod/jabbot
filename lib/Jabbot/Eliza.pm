package Jabbot::Eliza;
use Jabbot::Plugin -Base;
use Chatbot::Eliza;

const class_id => 'eliza';

field chatterbot => {},
    -init => 'Chatbot::Eliza->new()';

sub process {
    my $text = shift->text;
    # only replies to English
    $self->reply(
        ($text =~ /^[\x00-\x7f]/) ?
            $self->chatterbot->transform($text) : '')
}

