package Jabbot::OurNetChatBot;
use Jabbot::Plugin -Base;
use OurNet::ChatBot;
use Encode;

const class_id => 'ournet_chatbot';

field chatbot => {},
    -init => q{new OurNet::ChatBot($self->config->{nick},$self->chatdb,0)};

sub chatdb {
    io->catfile($self->plugin_directory,$self->config->{nick})->name
}

use YAML;
sub process {
    my $s = shift->text;
    my $big5_s = Encode::encode('big5',$s);
    my $reply = $self->chatbot->input($big5_s);
    my $utf8_reply = Encode::decode('big5',$reply);
    $self->reply($utf8_reply);
}
