package Jabbot::Config;
use Kwiki::Config -Base;


sub default_classes {
    (
        command_class => 'Jabbot::Command',
        config_class => 'Jabbot::Config',
        hooks_class => 'Spoon::Hooks',
        hub_class => 'Jabbot::Hub',
        messages_class => 'Jabbot::Messages',
        message_class => 'Jabbot::Message',
        registry_class => 'Jabbot::Registry',
        frontend_class => 'Jabbot::FrontEnd',
        backend_class => 'Jabbot::BackEnd',
    )
}

