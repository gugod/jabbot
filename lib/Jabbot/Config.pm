package Jabbot::Config;
use Kwiki::Config -Base;
our $VERSION = '0.01';

sub default_classes {
    (
        irc_class => 'Jabbot::IRC',
        command_class => 'Jabbot::Command',
        config_class => 'Jabbot::Config',
        formatter_class => 'Jabbot::Formatter',
        headers_class => 'Spoon::Headers',
        hooks_class => 'Spoon::Hooks',
        hub_class => 'Jabbot::Hub',
        javascript_class => 'Jabbot::Javascript',
        preferences_class => 'Jabbot::Preferences',
        registry_class => 'Jabbot::Registry',
    )
}

