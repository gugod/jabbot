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
        return $config if $config;

        my $x = root . "/config/site_config.yaml";
        $config = YAML::LoadFile(-f $x ? $x : root . "/config/config.yaml");
        return $config;
    }
}

1;

__END__

=head1 NAME

Jabbot - the multi-purpose bot.

=head1 COPYRIGHT

Copyright 2005,2006,2007,2008,2009,2010 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
