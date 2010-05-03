package Jabbot::Core;
use common::sense;
use HTTP::Lite;
use Plack::Request;
use JSON qw(to_json);

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub post {
    my ($self, %args) = @_;
     my $channel = $args{channel};
    my $text     = $args{text};

    if ($channel =~ m{^/irc/}) {
        my $server = "http://localhost:15001";

        my $http = HTTP::Lite->new;
        $http->prepare_post({ 'message[body]' => $text });
        $http->request("${server}${channel}");
    }
    return $self;
}

sub answer {
    my ($self, %args) = @_;
    my $answer = $args{question};
    return $answer;
}

sub app {
    my ($env) = @_;
    my $req = Plack::Request->new($env);

    my ($action) = $req->path =~ m[^/(\w+)$];
    return [404, [], ["ACTION NOT FOUND"]] unless $action;

    my $core = Jabbot::Core->new;
    return [404, [], ["ACTION NOT FOUND"]] unless $core->can($action);

    my $value = $core->$action(%{ $req->parameters });

    my $response_body =
        ($value == $core)
            ? "OK"
            : to_json({ $action => $value });

    return [200, [], [ $response_body ]];
}

1;
