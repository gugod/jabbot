package Jabbot;
use common::sense;
use Object::Tiny;
use Hash::Merge qw(merge);

sub new { bless {}, shift }

sub root {
    $ENV{'JABBOT_ROOT'}
}

use YAML;

{
    my $config;
    sub config {
        return $config if $config;

        my $config1 = YAML::LoadFile(root . "/config/config.yaml");
        my $config2 = {};
        my $x = root . "/config/site_config.yaml";
        $config2 = YAML::LoadFile($x) if -f $x;

        $config = merge($config1, $config2);
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
