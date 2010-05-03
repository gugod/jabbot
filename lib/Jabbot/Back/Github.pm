package Jabbot::Back::Github;
use common::sense;
use JSON qw(decode_json encode_json);
use Plack::Request;
use Jabbot::RemoteCore;

sub committer_name {
    my $commit = shift;
    my $name = $commit->{author}{email};
    $name =~ s/@.+$//;
    return $name;
}

sub build_commit_message {
    my $repo = shift;
    my $commit = shift;

    # trim message
    my $msg = substr($commit->{message} , 0 , 20) . ' ... ';

    my $committer = committer_name $commit ;
    my $m = sprintf("%s | %s++ | %s" ,
                   $repo ,
                   $committer,
                   $commit->{message});
    return $m;
}

sub app {
    my $env = shift;
    my $req = Plack::Request->new($env);

    return [404, [], ["NOT FOUND"]] if $req->path eq '/';

    my $payload = decode_json($req->param('payload'));
    my $repo    = $payload->{repository}{name};

    my $rc = Jabbot::RemoteCore->new;
    for my $commit (@{ $payload->{commits} || [] }) {
        $rc->post($req->path, build_commit_message($repo, $commit));
    }

    return [200, [], ["OK"]]
}

1;
