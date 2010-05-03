package Jabbot;
use common::sense;

sub new { bless {}, shift }

sub root {
    $ENV{'JABBOT_ROOT'}
}

use YAML;

{
    my $config;
    sub config {
        $config ||= YAML::LoadFile(root . "/config/config.yaml");
    }
}

1;

__END__

=head1 NAME

Jabbot - .

=head1 COPYRIGHT

Copyright 2005 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
