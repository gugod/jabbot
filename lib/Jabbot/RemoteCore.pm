package Jabbot::RemoteCore;
use common::sense;
use AnyEvent;
use AnyEvent::MP;
use AnyEvent::MP::Global;

my $self = bless {}, __PACKAGE__;

sub new {
    return $self;
}

configure;

grp_reg jabbot_remotecore => rcv
    port,
    reply => sub {
        my $data = shift;
        $self->{answers}->send(@{ $data->{answers} });
    };

sub answers {
    my ($self, %args) = @_;
    my @answers;
    my $q = $args{question};
    return if $self->{answers};

    $self->{answers} = AE::cv;

    my $ready;

    $ready = AE::idle sub {
        if (my $ports = grp_get "jabbot_core") {
            undef $ready;

            for (@$ports) {
                snd $_, action => { node => "jabbot_remotecore", name => "answers", args => \%args };
            }
        }
    };

    my @answers = $self->{answers}->recv;

    delete $self->{answers};
    return [sort { $b->{confidence} <=> $a->{confidence} } @answers];
}

sub answer {
    my ($self, %args) = @_;

    return $self->answers(%args)->[0];
}

1;

__END__

A console:

perl -Ilib -MJabbot::RemoteCore -E 'while(<>) { say Jabbot::RemoteCore->new->answer(question => $_)->{content}; } AE::cv->recv'
