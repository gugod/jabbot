package Jabbot::Plugin::zh_tw::RandomChatbot;
use common::sense;
use Acme::Lingua::ZH::Remix 0.14;

sub new { bless {}, shift }

sub can_answer { 1 }

sub answer {
    return {
        content    => rand_sentence,
        confidence => 0
    }
}

1;
