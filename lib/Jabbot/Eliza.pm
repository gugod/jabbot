package Jabbot::Eliza;
use Jabbot::Plugin -Base;
use Chatbot::Eliza;

const class_id => 'eliza';

field chatterbot => {},
    -init => 'Chatbot::Eliza->new()';

sub process {
    my $text = shift->text;
    # only replies to English
    
    my $r = $self->chatterbot->transform($text) if $text =~ /^\p{IsASCII}+$/;
    print STDERR "r= $r\n";
    if (defined($r) && $text =~ /thou|thy|thee|thine/)
    {
        print STDERR "[match oldenglish]\n";
        $r =~ s/have you/hast thou/gi;
        $r =~ s/your/thy/gi;
        $r =~ s/yours/thine/gi;
        $r =~ s/you/thou/gi;
    }
    $self->reply($r);
}

