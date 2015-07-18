package Jabbot::Core;
use v5.18;
use utf8;

use JSON qw(to_json);
use UNIVERSAL::require;
use Jabbot;
use Try::Tiny;

sub new {
    state $core;

    return $core if $core;

    my $class = shift;

    my $self = bless {}, $class;
    $self->{plugins} = [];
    $self->{services} = [];

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

        push @{ $self->{plugins} }, $plugin->new( core => $self );
    }

    $core = $self;
    return $self;
}

sub answer {
    my ($self, %args) = @_;
    my $answers = $self->answers(%args);
    return (sort { $b->{confidence} <=> $a->{confidence} } @$answers)[0];
}

sub answers {
    my ($self, %args) = @_;
    my @answers;
    my $q = $args{question};

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
    return \@answers;
}

sub register_service {
    my ($self, $srv) = @_;
    push @{ $self->{services} }, $srv;
}

1;
