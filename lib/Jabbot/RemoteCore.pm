package Jabbot::RemoteCore;
use common::sense;
use AnyEvent;
use AnyEvent::MP;
use AnyEvent::MP::Global;
use Scalar::Util qw(refaddr);
use YAML;

configure;

sub core_port {
    my $ports;

    $ports = grp_get "jabbot-core";

    if (@$ports == 0) {
        my $p = AE::cv;

        my $t;
        $t = AE::idle sub {
            $ports = grp_get "jabbot-core";

            if (@$ports > 0) {
                undef $t;
                $p->send;
            }
        };

        $p->recv;
    }

    return $ports->[0];
}

sub new {
    return bless {}, shift;
}

sub answers {
    my ($self, %args) = @_;
    my @answers;
    my $q = $args{question};

    my $answers = AnyEvent->condvar;

    my $ports = grp_get "jabbot-core";

    return [] unless $ports;

    snd $ports->[0], action => { name => "answers", args => \%args }, port {
        my ($data) = @_;
        $answers->send(@{ $data->{answers} });
    };

    return [sort { $b->{confidence} <=> $a->{confidence} } $answers->recv]
}

sub answer {
    my ($self, %args) = @_;

    my $ans = AE::cv;
    my $port = core_port;

    my $t;
    $t = AE::idle sub {
        snd $port, action => { name => "answer", args => \%args }, port {
            my (undef, $data) = @_;
            $ans->send($data);
            undef $t;
        };
    };

    return $ans->recv;
}

1;

__END__

A console:

perl -Ilib -MJabbot::RemoteCore -E 'while(<>) { say Jabbot::RemoteCore->new->answer(question => $_)->{content}; } AE::cv->recv'
