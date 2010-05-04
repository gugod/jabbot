package Jabbot::Core;
use common::sense;
use HTTP::Lite;
use Plack::Request;
use JSON qw(to_json);
use UNIVERSAL::require;
use Jabbot;
use Scalar::Defer;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->{plugins} = [];

    for my $plugin (map { "Jabbot::Plugin::$_"} @{Jabbot->config->{plugins}}) {
        $plugin->require;
        say STDERR "- Initiating $plugin";
        push @{ $self->{plugins} }, $plugin->new;
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
    my @answers;
    for my $plugin (@{$self->{plugins}}) {
        if ($plugin->can_answer($args{question})) {
            my $a = $plugin->answer($args{question});
            $a->{plugin} = ref $plugin;
            push @answers, $a;
        }
    }

    return "" if @answers == 0;
    return $answers[0] if @answers == 1;

    my @x = sort { $b->{confidence} <=> $a->{confidence} } @answers;
    return $x[0];
}

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

1;
