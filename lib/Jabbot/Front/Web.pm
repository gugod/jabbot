package Jabbot::Front::Web;
use v5.12;
use common::sense;

use AnyEvent;
use AnyEvent::MP;
use AnyEvent::MP::Global;

use Jabbot;
use Plack::Request;
use Plack::Response;
use Encode qw(encode_utf8);
use JSON;
use Jabbot::RemoteCore;

sub app {
    my ($env) = @_;
    my $req = Plack::Request->new($env);

    my $from = $req->param("f") || "someone";
    my $text = $req->param("s");

    my $message = {
        network  => "Web",
        channel  => "Web",
        from     => $from,
        to       => Jabbot->config->{nick},
        question => $text
    };

    my $jabbot = Jabbot::RemoteCore->new;
    my $reply = $jabbot->answer(%$message);

    my $res = Plack::Response->new(200);
    $res->content_type('text/x-json');

    my $json = JSON->new;

    $res->body( encode_utf8( $json->encode($reply) ) );

    return $res->finalize;
}

sub run {
    require Plack::Runner;

    my $runner = Plack::Runner->new;
    $runner->parse_options("--port" => "15203");
    $runner->run(\&app);
}

1;
