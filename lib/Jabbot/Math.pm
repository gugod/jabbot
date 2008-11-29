package Jabbot::Math;
use Jabbot::Plugin -Base;
use Math::Expression;

field 'class_id' => "math";

field 'pasred';

sub test {
    my $text = shift;
    return $text =~ m{^[\s\d\+\-\*\/^]+$};
}

sub process {
    my $msg = shift;
    my $text = $msg->text;

    $text =~ s/^\s+//; $text =~ s/\s*\?*\s*$//;

    return unless $self->test($text);

    my $m = new Math::Expression;
    my $tree = $m->Parse($text);
    return unless $tree;

    my $reply = $m->EvalToScalar($tree);
    $self->reply($reply, 1) unless $reply eq $text;
}
