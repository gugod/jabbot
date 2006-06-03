package Text::Ngrams::Extensions;
use strict;
use warnings;

package Text::Ngrams;
use Math::Orthonormalize qw(normalize);

sub dot_product_with {
    my ($self, $other) = @_;
    my %ng_self = $self->get_normalized_ngrams;
    my %ng_other = $other->get_normalized_ngrams;
    my $dp = 0;
    for ( keys %ng_self ) {
        $dp += $ng_self{$_} * ($ng_other{$_} ||0);
    }
    return $dp;
}

sub get_normalized_ngrams {
    my ($self) = @_;
    my %ng = $self->get_ngrams;
    my @k = keys %ng;
    my @v = values %ng;
    my @normalized_v = @{normalize([@v])};
    @ng{@k} = @normalized_v;
    return %ng;
}

package Text::Ngrams::Extensions;
1;

__END__

=head1 NAME

Text::Ngrams::Extensions - Extends Text::Ngrams

=head1 COPYRIGHT

Copyright 2006 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
