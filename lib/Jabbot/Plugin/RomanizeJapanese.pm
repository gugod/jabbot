package Jabbot::Plugin::RomanizeJapanese;
use common::sense;
use Object::Tiny;
use Lingua::JA::Romanize::Japanese;
use self;

sub can_answer {
    my ($text) = @args;
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
    return join " ", map { defined($_->[1]) ? "$_->[0]($_->[1])" : "$_->[0]" } $self->romanizer->string($self->{matched});}
}

1;

