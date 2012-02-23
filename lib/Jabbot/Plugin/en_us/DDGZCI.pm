package Jabbot::Plugin::en_us::DDGZCI;
use v5.14;
use Jabbot::Plugin;
use WWW::DuckDuckGo;

sub can_answer {
    my ($text) = @args;
    my ($question) = $text =~
        /^(?:
             what \s* is|
             what's|
             do \s+ you \s+ know
         )
         \s+
         (.+)
         \?+\s*$/ix;

    if ($question) {
        $self->{question} = $question;
        return 1;
    }

    return 0;
}

sub answer {
    my ($text) = @args;

    my $duck = WWW::DuckDuckGo->new;
    my $result = $duck->zci($text);

    return unless $result->has_abstract;

    return {
        content    => $result->abstract,
        confidence => 0.9
    }
}

1;
