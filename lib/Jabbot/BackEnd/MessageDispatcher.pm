package Jabbot::BackEnd::MessageDispatcher;
use strict;
use warnings;
use Jabbot::BackEnd -base;
use POE qw(Session
           Component::IKC::Server
           Component::IKC::Specifier
           Component::IKC::ClientLite);

use YAML;

# This backend dispatch messages from other backends to specified
# frontends. Therefore, this module is a ikc client and server.

my $self;
my $name = 'MessageDispatcher';

sub process {
    $self = shift;
    create_ikc_server(
        port => $self->config->{message_dispatcher_port},
        name => $name
       );
    POE::Session->create(
        heap => { frontends => [] },
        inline_states => {
            _start => \&on_start,
            message => \&on_message,
            register => \&on_register,
           }
       );
    $poe_kernel->run();
}

sub on_start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    $kernel->alias_set("MessageDispatcher");
    $kernel->call(IKC => publish => $name => ['message','register']);
    say "Message Dispatcher Started";
}

sub on_register {
    my ($kernel,$heap,$msg) = @_[KERNEL,HEAP,ARG0];
    push @{$heap->{frontends}}, {
        name => $msg->{name},
        port => $msg->{port},
       };
}

sub on_message {
    my ($kernel,$heap,$msg) = @_[KERNEL,HEAP,ARG0];

    print YAML::Dump($msg);

#     for my $frontend (@{$heap->{frontends}}) {
#         my $remote = POE::Component::IKC::ClientLite::create_ikc_client(
#             port => $frontend->{port},
#             name => "CheatConsole$$",
#            ) or die $POE::Component::IKC::ClientLite::error;
#         $remote->post("$frontend->{name}/message",$msg)
#             if($frontend->{name} eq $msg->{frontend});
#     }

}

1;
