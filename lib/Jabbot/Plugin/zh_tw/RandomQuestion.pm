package Jabbot::Plugin::zh_tw::RandomQuestion;
use v5.18;
use utf8;
use Object::Tiny qw(core);

use Acme::Lingua::ZH::Remix 0.90;

sub can_answer {
    my ($self, $message) = @_;
    my $text = $message->{body};
    $text =~ s/\s*[\!\?？！]+\s*\z//;

    # XXX: Chained comparison
    my $len = length($text);
    if (2 <= $len && $len < 4) {
        $self->{__token} = $text;
        return 0.5;
    }
    return 0;
}

sub answer {
    my ($self, $message) = @_;
    my $text = $self->{__token} . "是甚麼意思？";
    return {
        body  => $text,
        score => 0.6,
    }
}

1;
