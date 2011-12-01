package Jabbot::Back::GitHub;
use common::sense;
use JSON qw(decode_json encode_json);
use Plack::Request;
use AnyEvent;
use AnyEvent::MP;
use AnyEvent::MP::Global;

sub committer_name {
    my $commit = shift;
    my $name = $commit->{author}->{name};
    # $name =~ s/@.+$//;
    return $name;
}

sub build_commit_message {
    my $repo = shift;
    my $commit = shift;

    # trim message
    my $msg = substr( shift(split(/\n/,$commit->{message})) , 0 , 20) . ' ... ';
    my $committer = committer_name $commit;
    return sprintf("%s | %s++ | %s" , $repo , $committer, $commit->{message});
}

sub app {
    my $env = shift;
    my $req = Plack::Request->new($env);

    return [404, [], ["NOT FOUND"]] if $req->path eq '/';

    my ($network, $channel) = $req->path =~ m{/networks/([^/]+)/channels/([^/]+)};
    my $irc = grp_get "jabbot-irc";

    return [404, [], ["NOT FOUND"]] unless $network && $channel && $irc;

    my $payload = decode_json($req->param('payload'));
    my $repo    = $payload->{repository}{name};

    unless ($channel =~ /^[#&+!]/) {
        $channel = "#" . $channel;
    }

    my $cnt = 0;
    my $limit = 3;
    my @commits = @{ $payload->{commits} || [] };
    for my $commit ( @commits ) {
        if(++$cnt > $limit ) {  # avoid flood
            snd $_ , post => { 
                network => $network,
                channel => $channel,
                command => 'NOTICE',
                body => 'and pushed other ' . (scalar(@commits) - $cnt). ' commits.'
            } for @$irc;
        }

        snd $_, post => {
            network => $network,
            channel => $channel,
            command => 'NOTICE',
            body    => build_commit_message($repo, $commit)
        } for @$irc;
    }

    return [200, [], ["OK"]]
}

sub run {
    configure profile => "jabbot-github";

    require Plack::Runner;

    my $runner = Plack::Runner->new(server => "Twiggy", env => "production");
    $runner->parse_options("--port" => "15201");
    $runner->run(\&app);
}

1;
__END__

=pod

GitHub post-hook

L<http://help.github.com/post-receive-hooks/>

=cut
