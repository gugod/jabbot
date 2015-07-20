package Jabbot::Plugin::RomanizeJapanese;
use v5.18;
use Object::Tiny;

use Lingua::JA::Romanize::Japanese;

sub can_answer {
    my ($self, $text) = @_;
    if ($text =~ /^\s*romanize\s+(j[ap]|japanese)\s+(.+)$/i) {
        $self->{matched} = $2;
    }
}

{
    my $x;
    sub romanizer {
        return $x if $x;
        $x = Lingua::JA::Romanize::Japanese->new
    }
}

sub answer {
    my ($self, $text) = @_;
    my $reply_text = join " ", map { defined($_->[1]) ? "$_->[0]($_->[1])" : "$_->[0]" } $self->romanizer->string($self->{matched});
    return {
        score => 1,
        body => $reply_text,
    }
}

1;

