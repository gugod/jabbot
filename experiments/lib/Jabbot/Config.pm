package Jabbot::Config;

=head1 NAME

Jabbot::Config -- Jabbot Config class

=cut

use strict;
use Spoon::Config '-base';
use Spoon::Installer '-base';

const class_id => 'config';

sub default_configs {
    my $self = shift;
    my @configs;
    push @configs, "$ENV{HOME}/.jabbot/config.yaml"
      if defined $ENV{HOME} and -f "$ENV{HOME}/.jabbot/config.yaml";
    push @configs, "config.yaml"
      if -f "config.yaml";
    return @configs;
}

sub default_config {
    return {
            main_class => 'Jabbot',
            config_class => 'Jabbot::Config',
            hub_class => 'Jabbot::Hub',
	   };
}

1;


=head1 COPYRIGHT

Copyright by gugod@gugod.org.

=cut
