package Jabbot::Plugin::Delicious;
use Jabbot::Plugin;
use Jabbot;
use Net::Delicious;
use Regexp::Common qw/URI/;
use YAML;

sub can_answer {
    my ($text, $message) = @args;
    if ($text =~ /^(?:!d(?:elicious)?) +($RE{URI}{HTTP})(?: +tags:(.+?))?$/i) {
        $self->{url} = $1;
        $self->{tags} = $2;
        return 1;
    }
    return 0;
}

sub answer {
    my ($text, $message) = @args;
    return unless $self->{url};

    my $reply = "Posting failed due to alien invasion.";

    say "HUH";

    if ($self->post_to_delicious($self->{url})) {
        $reply = "Yummy.";
        say "Yummy";
    }

    say YAML::Dump($self);


    return { reply => $reply,  confidence => 0.9 };
}

sub post_to_delicious {
    my ($url) = @args;

    my $config = Jabbot->config->{delicious};
    my $del = Net::Delicious->new({ user => $config->{username}, pswd => $config->{password}, debug => 1 });

    return $del->add_post({ url => $url, tags => "auto jabbot" });
}

1;
