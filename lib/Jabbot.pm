package Jabbot;
use v5.12;
use common::sense;
use Object::Tiny;
use Hash::Merge;

use Cwd ();

{
    my $root;
    sub root {
        return $root if $root;
        $root = $ENV{'JABBOT_ROOT'} || Cwd::getcwd();
        return $root;
    }
}

use YAML;

{
    my $config;
    sub config {
        return $config if $config;

        my $config1 = YAML::LoadFile(root . "/config/config.yaml");
        my $config2 = {};
        my $x = root . "/config/site_config.yaml";

        if( -e $x ) {
            $config2 = YAML::LoadFile($x);
        }

        my $merger = Hash::Merge->new('RIGHT_PRECEDENT');
        $config = $merger->merge($config1, $config2);
        return $config;
    }
}

use Jabbot::Memory;
sub memory { "Jabbot::Memory" }

1;

__END__

=head1 NAME

Jabbot - the multi-purpose bot.

=head1 COPYRIGHT

Copyright 2005,2006,2007,2008,2009,2010,2011 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
