package Jabbot::Math;
use Jabbot::Plugin -Base;
use Math::Expression::Evaluator;

field 'class_id' => "math";

sub process {
    my $msg = shift;
    my $text = $msg->text;

    $text =~ s/^\s+//;
    $text =~ s/\s*\?*\s*$//;

    my $m = Math::Expression::Evaluator->new;
    my $tree = $m->parse($text);
    return unless $tree;

    my $reply = $tree->val();
    $self->reply($reply, 1) unless $reply eq $text;
}
