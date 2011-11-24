package Jabbot::Back::Irccat;
use common::sense;
use JSON qw(decode_json);
use Plack::Request;
use Try::Tiny;
use AnyEvent;
use AnyEvent::MP;
use AnyEvent::MP::Global;
use YAML;
use Jabbot;

sub app {
    my $env = shift;
    my $req = Plack::Request->new($env);

    return [404, [], ["NOT FOUND"]] if $req->path eq '/';

    my ($network, $channel) = $req->path =~ m{/networks/([^/]+)/channels/([^/]+)};
    my $irc = grp_get "jabbot-irc";

    return [404, [], ["NOT FOUND"]] unless $network && $channel && $irc;

    my $payload = {};

    if ($req->content_type =~ '^multipart/form-data;') {
        for (qw(token body command)) {
            $payload->{$_} = $req->param($_);
        }
    }
    else {
        try {
            $payload = decode_json($req->content);
        }
    }

    unless (ref($payload) eq 'HASH' && $payload->{token} && $payload->{body}) {
        return [400, [], ["NEED TOKEN AND BODY"]];
    }

    unless( grep { $payload->{token} eq $_ } @{Jabbot->config->{irccat}{tokens}} ) {
        return [403, [], ["TOKEN NOT MATCHED"]];
    }

    $channel = "#" . $channel unless $channel =~ /^[#&+!]/;

    my $message = {
        network => $network,
        channel => $channel,
        body    => $payload->{body}
    };

    $message->{command} = $payload->{command} if defined($payload->{command});

    snd $_, post => $message for @$irc;

    return [200, [], ["OK"]]
}

sub run {
    configure;

    require Plack::Runner;

    my $runner = Plack::Runner->new(env => "production");
    $runner->parse_options("--port" => "15202");
    $runner->run(\&app);
}

1;
__END__

=pod

irccat as web api.

    POST /networks/:network/channels/:channel

    HTTP request body can be a json like this:

    {
        token => "xxx",      // anti-abuse
        body => "...",
        command => "notice", // optional. default to "privmsg"
    }

    Or encoded as multipart/form with "token", "body", "command" fields.

Testing:

    curl -D - -X POST --data-binary '{"token":"b00814438ff3c7433a2248e725b8e7d2080cfb5f","body":"ohai"}' http://localhost:15202/networks/freenode/channels/jabbot

    curl -D - -X POST -d token=b00814438ff3c7433a2248e725b8e7d2080cfb5f -d body=ohai http://localhost:15202/networks/freenode/channels/jabbot

=cut
