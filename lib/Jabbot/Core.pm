package Jabbot::Core;
use v5.18;
use utf8;

use Jabbot;
use Jabbot::Types qw(JabbotMessage);

use JSON qw(to_json);
use UNIVERSAL::require;

sub new {
    state $core;

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

        push @{ $self->{plugins} }, $plugin->new( core => $self );
    }

    $core = $self;
    return $self;
}

sub answers {
    my ($self, $message) = @_;
    JabbotMessage->assert_valid($message);

    my @answers;
    for my $plugin (@{$self->{plugins}}) {
        next unless $plugin->can_answer($message);
        my $plugin_name = ref($plugin) =~ s/^Jabbot::Plugin:://r;
        eval {
            my $a = $plugin->answer($message);
            if (ref($a) eq 'HASH') {
                $a->{plugin} = $plugin_name;
                push @answers, $a;
            }
            1;
        } or do {
            my $err = $@ || "(zombie error)";
            warn "[Jabbot::Core][ERROR][plugin=${plugin_name}] $err";
        }
    }
    return \@answers;
}

1;
