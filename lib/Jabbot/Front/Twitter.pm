package Jabbot::Front::Twitter;
use v5.36;

use Jabbot;
use Jabbot::Types qw(JabbotMessage);

use Encode qw(encode_utf8);
use Twitter::API;

use Mojo::JSON qw(decode_json);
use Mojolicious::Lite;

my $config = Jabbot->config->{twitter};

sub tweet_this {
    my $message = shift;
    JabbotMessage->assert_valid($message);

    my $client = Twitter::API->new_with_traits(
        traits => 'Enchilada',
        consumer_key    => $config->{consumer_key},
        consumer_secret => $config->{consumer_secret},
        access_token => $config->{access_token},
        access_token_secret => $config->{access_token_secret},
    );

    my $res = $client->update($message->{body});

    return $res->{id_str};
}

get '/' => sub {
    my $c = shift;
    $c->render(json => {
        name  => "jabbot-tweetd",
    });
};

post '/' => sub {
    my $c = shift;
    my $res = {};
    my @error;
    my $req = decode_json( $c->req->body );
    if (!defined($req->{body})) {
        push @error, "\"body\" is missig";
    }
    my $tweet_id = tweet_this({
        network => "twitter",
        channel => $config->{username},
        author  => $config->{username},
        body => $req->{body},
    });
    if ($tweet_id) {
        $res->{tweet_id} = $tweet_id;
    } else {
        $res->{error} = "failed tweeting";
    }

    $c->render(json => $res);
};

app->start;
