package Jabbot::Plugin::zh_tw::UrbanFacts;
use strict;
use warnings;
use utf8;
use Object::Tiny;

my $ymodifiers = "好像|應該|就|也|乃|只|衹|真的|真";

sub can_answer {
    my ($self, $message) = @_;
    my $text = $message->{body};
    return 1 if $text =~ /$ymodifiers/;
}

sub answer {
    my ($self, $message) = @_;
    my $text = $message->{body};
    return {
        body  => "",
        score => 0
    }
}


1;
