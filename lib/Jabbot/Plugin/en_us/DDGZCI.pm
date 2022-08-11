package Jabbot::Plugin::en_us::DDGZCI;
use v5.36;

use Object::Tiny;
use WWW::DuckDuckGo;

sub can_answer {
    my ($self, $message) = @_;
    my $text = $message->{body};
    my ($question) = $text =~
        /\A(?:
             what \s* is|
             what's|
             do \s+ you \s+ know
         ) \s+
         (.+) \s*
         \?+ \s* \z/ix;

    unless ($question) {
        ($question) = $text =~
            m/^(?:
                  !ddg |
                  give \s+ me \s+ an? |
                  tell \s+ me \s+ about
              )
              \s+ (.+) \s* $
             /ix;
    }

    if ($question) {
        $self->{question} = $question;
        return 1;
    }

    return 0;
}

sub answer {
    my ($self, $message) = @_;
    my $text = $message->{body};

    my $duck = WWW::DuckDuckGo->new;

    my $result = $duck->zci($self->{question});

    my $content;

    for (qw(abstract answer)) {
        $content = $result->$_ if $result->can("has_$_")->($result);
    }

    return unless $content;

    return {
        body  => $content,
        score => 1,
    }
}

1;
