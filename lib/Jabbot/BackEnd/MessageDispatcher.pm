package Jabbot::Backend::MessageDispatcher;
use Jabbot::Backend -base;
use POE::Component::IKC::Server;
use POE::Component::IKC::ClientLite;

# This backend dispatch messages from other backends to specified
# frontends. Therefore, this module is a ikc client and server.

my $self;
my $name = 'MessageDispatcher';

sub process {
    $self = shift;
    POE::Component::IKC::Server->spawn(
        port => $self->config->{message_dispatcher_port},
        name => $name
       );
    POE::Session->create(
        inline_states => {
            heap => { frontends => {} }
            _start => sub {
                my($kernel) = @_[KERNEL];
                $kernel->call(IKC=>publish=>$name=>['message']);
                $kernel->call(IKC=>publish=>$name=>['register']);
            },
            message => \&on_message,
            register => \&on_register,
           }
       );
    POE::Kernel->run();
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

    for my $frontend (@{$heap->{frontends}}) {
        my $remote = POE::Component::IKC::ClientLite::create_ikc_client(
            port => $frontend->{port},
            name => "CheatConsole$$",
           ) or die $POE::Component::IKC::ClientLite::error;
        $remote->post("$frontend->{name}/message",$msg)
            if($frontend->{name} eq $msg->{frontend});
    }
}

1;
