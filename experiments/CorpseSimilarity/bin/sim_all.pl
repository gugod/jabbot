#!/usr/bin/perl -w

eval 'exec /usr/bin/perl -w -S $0 ${1+"$@"}'
    if 0; # not running under some shell

use lib 'lib';
use strict;
use warnings;
use Pod::Usage;

use Text::Ngrams;
use Text::Ngrams::Extensions;
use Perl6::Say;
use File::Basename;

my $dir = shift;

my @ng = map {
    my $ng = Text::Ngrams->new( type => 'utf8');
    $ng->process_files($_);
    $ng->{file_name} = basename($_);
    $ng;
} <$dir/*.txt>;

my $dp={};
for my $i (0..$#ng) {
    for my $j ($i+1..$#ng) {
        $dp->{$ng[$i]->{file_name}}{$ng[$j]->{file_name}} = $ng[$i]->dot_product_with($ng[$j]);
    }
}

use YAML;
say YAML::Dump($dp);

__END__

=head1 NAME

sim_all.pl - Calculator similarity for all pairs of files in a dir

=head1 SYNOPSIS

Aliquam velit suscipit tation adipiscing. Volutpat ullamcorper dolore magna,
vel sit in aliquip accumsan diam velit in feugait suscipit: tation. Ut et
dolore veniam dolore dolore feugait: laoreet wisi lobortis consequat minim
exerci. At exerci duis duis nibh. Consequat duis molestie sed esse in at augue
iriure velit tation. Facilisis iriure duis eum illum duis nibh vel ut elit
hendrerit. Dolore te blandit elit ipsum eros feugiat erat.

=head1 SEE ALSO

=head1 COPYRIGHT

Copyright 2006 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
