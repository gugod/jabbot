package Jabbot::Core;
use common::sense;
use HTTP::Lite;
use Plack::Request;
use JSON qw(to_json);
use UNIVERSAL::require;
use Jabbot;
use Data::Thunk qw(lazy);
use Try::Tiny;

sub new {
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

    return $self;
}

sub post {
    my ($self, %args) = @_;
    my $channel = $args{channel};
    my $text     = $args{text};

    if ($channel =~ m{^/irc/}) {
        my $server = Jabbot->config->{irc}{listen};

        my $http = HTTP::Lite->new;
        $http->prepare_post({ 'message[body]' => $text });
        $http->request("http://${server}${channel}");
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
        if ($plugin->can("can_answer")) {
            if ($plugin->can_answer($q)) {
                try {
                    my $a = $plugin->answer($q);
                    if (ref $a eq 'HASH') {
                        $a->{plugin} = ref $plugin;
                        $a->{plugin} =~ s/^Jabbot::Plugin:://;
                        push @answers, $a
                    }
                }
            }
        }
        else {
            warn ">>> $plugin need to respond 'can_answer' method, but it does not.\n";
        }
    }
    return [sort { $b->{confidence} <=> $a->{confidence} } @answers];
}

{
    my $core = lazy { Jabbot::Core->new };

    sub app {
        my ($env) = @_;
        my $req = Plack::Request->new($env);

        my ($action) = $req->path =~ m[^/(\w+)$];
        return [404, [], ["ACTION NOT FOUND"]] unless $action && $core->can($action);

        my $value = $core->$action(%{ $req->parameters });

        my $response_body =
            ($value == $core)
                ? to_json({ $action => "OK"   }, { utf8 => 1 })
                    : to_json({ $action => $value }, { utf8 => 1 });

        return [200, [], [ $response_body ]];
    }
}

1;
