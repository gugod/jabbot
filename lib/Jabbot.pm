package Jabbot;
use v5.12;
use common::sense;
use Object::Tiny;
use Hash::Merge;
use Path::Class;
use YAML;
use Jabbot::Memory;

## Returns a Path::Class::Dir object.
sub root {
    state $root;

    return $root if defined $root;

    if ($ENV{JABBOT_ROOT}) {
        $root = dir($ENV{JABBOT_ROOT});
    }
    else {
        $root = file(__FILE__)->absolute->dir->parent;
    }

    return $root;
}

sub config {
    state $config;

    return $config if defined $config;

    my $config1 = YAML::LoadFile( root->file("config", "config.yaml") );
    my $config2 = {};
    my $x = root . "/config/site_config.yaml";

    if ( -e $x ) {
        $config2 = YAML::LoadFile($x);
    }

    $config = Hash::Merge->new('RIGHT_PRECEDENT')->merge($config1, $config2);

    return $config;
}

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
