package Jabbot::RomanizeJapanese;
use Jabbot::Plugin -Base;
use Lingua::JA::Romanize::Japanese;
use Encode;

const class_id => 'romanize_japanese';

sub process {
    my $s = shift->text;
    if ( $s =~ /^\s*romanize\s+(j[ap]|japanese)\s+(.+)$/i) {
        my $reply = $self->romanize( $2 );
        $self->reply($reply, 1);
    }
}

field romanizer => -init => 'Lingua::JA::Romanize::Japanese->new';

sub romanize {
    my $string = shift;
    $string = encode('utf8', $string)
        if ( Encode::is_utf8($string) );
    my $out = join " ",
    map { defined($_->[1]) ? "$_->[0]($_->[1])" : "$_->[0]" }
    $self->romanizer->string( $string );
    $out = decode('utf8', $out);
    return $out;
}

