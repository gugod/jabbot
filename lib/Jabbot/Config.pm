package Jabbot::Config;
use Kwiki::Config -Base;
our $VERSION = '0.01';

sub default_classes {
    (
        irc_class => 'Jabbot::IRC',
        console_class => 'Jabbot::Console',
        command_class => 'Jabbot::Command',
        config_class => 'Jabbot::Config',
        hooks_class => 'Spoon::Hooks',
        hub_class => 'Jabbot::Hub',
        registry_class => 'Jabbot::Registry',
    )
}

