Jabbot
======
Jabbot is now under ∞.0 developement. It's based on Plack and AnyEvent.

Port number allocation:

- core:  15000
- front:
  - irc: 15101
- back:
  - github: 15201

Current Status
--------------

    lib/Jabbot/Back       - new anyevent backend
    lib/Jabbot/BackEnd    - old backend

    lib/Jabbot/Front      - new anyevent frontend
    lib/jabbot/FrontEnd   - old frontend

Setup
-----
Make sure AnyEvent::MP is installed.

copy and edit config:

    cp config/config.yaml config/site_config.yaml
    vim config/site_config.yaml

setup anyevent mp group node:

    bin/jabbot-setup

boot up jabbot core, irc and any other daemons:

    bin/jabbot-boot


Debugging
---------

    export PERL_ANYEVENT_MP_TRACE=1
    perl bin/jabbot-irccat freenode "#chupei.pm" testing message

Hacking
-------

To create a new backend:

Declare a class in `lib/Jabbot/Back/NewBack.pm`, a basic structure:

    package Jabbot::Back::NewBack;
    use common::sense;
    use JSON qw(decode_json encode_json);
    use AnyEvent;
    use AnyEvent::MP;
    use AnyEvent::MP::Global;
    use AnyEvent::HTTP;

    sub run {
        configure profile => "jabbot-newback";
        my $config = Jabbot->config->{newback};  # hash
        my $irc    = grp_get "jabbot-irc";       # get irc object
        snd $_ , post => { 
            network => 'freenode',
            channel => 'chupei.pm',
            body    => 'public message',
                } for @$irc;
    }

    1;


To create a basic plugin, you should consult the URLPreview plugin `lib/Jabbot/Plugin/URLPreview.pm`,
it's pretty simple. the basic structure:

    package Jabbot::Plugin::URLPreview;
    use warnings;
    use strict;
    use Jabbot::Plugin;
    use LWP::Simple;
    use Web::Query;

    sub can_answer {

        # $self is inject from 'self' module.

        return 1;  # return true or false
    }

    sub answer {
        my ($text) = @args;

        # $self is inject from 'self' module.

        return { content => 'reply', confidence => 1 };
    }

    1;

