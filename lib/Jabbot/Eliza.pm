package Jabbot::Eliza;
use Jabbot::Plugin -Base;
use Chatbot::Eliza;

field chatterbot => {}.
    -init => 'new Chatbot::Eliza';

sub process {
    $mybot->transform( $string );
}
