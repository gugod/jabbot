package Jabbot::Plugin::zh_tw::Polite;
use Jabbot::Plugin;

sub can_answer {
    my ($text) = @args;

    return $text =~ /謝謝/;
}

sub answer {
    return {
        content    => "不客氣",
        confidence => 0.5
    }
}

1;
