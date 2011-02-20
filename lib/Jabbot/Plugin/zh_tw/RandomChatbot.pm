package Jabbot::Plugin::zh_tw::RandomChatbot;
use common::sense;
use Object::Tiny;
use Acme::Lingua::ZH::Remix 0.90;
use self;

sub can_answer {
    my ($text) = @args;
    return (length($text) > 2);
}

sub answer {
    $self->{remix} ||= Acme::Lingua::ZH::Remix->new;
    return {
        content    => $self->{remix}->random_sentence,
        confidence => 0 - rand
    }
}

1;
