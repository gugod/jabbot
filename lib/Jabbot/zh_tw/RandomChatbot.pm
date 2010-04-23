package Jabbot::zh_tw::RandomChatbot;
use Jabbot::Plugin -Base;
use Acme::Lingua::ZH::Remix 0.14;

const class_id => 'zh_tw_random_chatbot';

sub process {
    my $msg = shift;
    my $s = $msg->text;
    if ($msg->me) {
        $self->reply( rand_sentence );
    }
}

1;
