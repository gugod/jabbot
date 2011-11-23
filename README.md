Jabbot
======
Jabbot is now under 4.0 developement. It's based on Plack and AnyEvent.

Port number allocation:

core:  15000
front:
  irc: 15101
back:
  github: 15201



Current Status
--------------

    lib/Jabbot/Back       - new anyevent backend
    lib/Jabbot/BackEnd    - old backend

    lib/Jabbot/Front      - new anyevent frontend
    lib/jabbot/FrontEnd   - old frontend

Getting Started
---------------

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
        my $irc    = grp_get "jabbot-irc";       # irc object
        snd $_ , post => { 
            network => 'freenode',
            channel => 'chupei.pm',
            body    => 'public message',
                } for @$irc;
    }

    1;
