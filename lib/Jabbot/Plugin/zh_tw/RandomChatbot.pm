package Jabbot::Plugin::zh_tw::RandomChatbot;
use common::sense;
use Object::Tiny;
use Acme::Lingua::ZH::Remix 0.90;
use self;

sub can_answer {
    my ($text) = @args;
    return (lenght($text) > 3);
}

sub answer {
    my $remix = Acme::Lingua::ZH::Remix->new;
    return {
        content    => $remix->random_sentence,
        confidence => 0
    }
}

1;
