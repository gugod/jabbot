package Jabbot::Core;
use 5.012;
use common::sense;
use JSON qw(to_json);
use UNIVERSAL::require;
use Jabbot;
use Try::Tiny;

use AnyEvent;
use AnyEvent::MP;
use AnyEvent::MP::Global;

configure;

my $core;
sub new {
    return $core if $core;

    my $class = shift;

    my $self = bless {}, $class;
    $self->{plugins} = [];

    for my $plugin (map { "Jabbot::Plugin::$_"} @{Jabbot->config->{plugins}}) {
        unless ($plugin->require) {
            warn "* $plugin failed to be loaded.\n";
            next;
        }

        unless ($plugin->can('can_answer') && $plugin->can('answer') &&
            $plugin->can('can_answer') != \&Jabbot::Plugin::can_answer &&
            $plugin->can('answer')     != \&Jabbot::Plugin::answer) {
            warn "* $plugin not loaded due to the lack of 'can_answer' or 'answer' method\n";
            next;
        }

        push @{ $self->{plugins} }, $plugin->new;
        warn "* LOAD $plugin\n";
    }

    $core = $self;
    return $self;
}

sub post {
    my ($self, %args) = @_;
    my $channel = $args{channel};
    my $text    = $args{text};

    my $ports = grp_get "jabbot_irc"
        or return;

    if ($channel =~ m{^/irc/networks/([^/]+)/channels/([^/]+)}) {
        my ($irc_network, $irc_channel) = ($1, $2);

        for (@$ports) {
            snd $_, message => {
                network => $irc_network,
                channel => $irc_channel,
                body    => $text
            };
        }
    }
    return $self;
}

sub answer {
    my ($self, %args) = @_;
    return $self->answers(%args)->[0];
}

sub answers {
    my ($self, %args) = @_;
    my @answers;
    my $q = $args{question};

    utf8::decode($q) unless utf8::is_utf8($q);

    for my $plugin (@{$self->{plugins}}) {
        if ($plugin->can_answer($q, \%args)) {
            try {
                my $a = $plugin->answer($q, \%args);
                if (ref $a eq 'HASH') {
                    $a->{plugin} = ref $plugin;
                    $a->{plugin} =~ s/^Jabbot::Plugin:://;
                    push @answers, $a;
                }
            }
        }
    }
    return [sort { $b->{confidence} <=> $a->{confidence} } @answers];
}

sub run {
    my $self = Jabbot::Core->new;
    my $port = rcv(
        port,
        action => sub {
            my ($data, $reply_port) = @_;
            my $name = $data->{name};

            $reply_port ||= (grp_get("jabbot_irc") || [])->[0];

            return unless $self->can($name);

            my $reply;

            try {
                $reply = $self->$name(%{$data->{args}});

                snd $reply_port, reply => {
                    $name => $reply,
                    network => $data->{args}{network},
                    channel => $data->{args}{channel},
                    from    => $data->{args}{from},
                    to_me   => $data->{args}{to_me},
                }
            } catch {
                say "ERROR:  $_";
            };
        }
    );

    my $guard = grp_reg "jabbot_core", $port;
    AnyEvent->condvar->recv
}

1;
