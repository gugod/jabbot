package Jabbot::Config;
use Kwiki::Config -Base;
use mixin 'Kwiki::Installer';
use YAML;

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

sub parse_yaml {
    my $str = shift;
    YAML::Load($str);
}

__DATA__
__config/config.yaml__
message_dispatcher_port: 65000
irc_frontend_port: 65123
irc_networks:
- freenode
# - localhost
# - ircnet

irc_freenode_server: irc.freenode.net
irc_freenode_port: 6667
irc_ircnet_server: irc.ircnet.net
irc_ircnet_port: 6666
irc_localhost_server: 127.0.0.1

nick: jabbot3
irc_channels:
- freenode:jabbot3

default_encoding: utf8
