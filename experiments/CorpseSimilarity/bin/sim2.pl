#!/usr/bin/perl -l

eval 'exec /usr/bin/perl -w -S $0 ${1+"$@"}'
    if 0; # not running under some shell

use lib 'lib';
use strict;
use warnings;
use Pod::Usage;
use Text::Ngrams;
use Text::Ngrams::Extensions;

my @ng = map {
    my $ng = Text::Ngrams->new( type => 'utf8');
    $ng->process_files($_);
    $ng;
} @ARGV[0,1];

my $dp = $ng[0]->dot_product_with($ng[1]);

print "Similarity $dp";

__END__

=head1 NAME

sim2.pl - Determin the similarity between two text files

=head1 SYNOPSIS


 sim2.pl file1.txt file2.txt

=head1 SEE ALSO

=head1 COPYRIGHT

Copyright 2006 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
