package Jabbot::Plugin::Delicious;
use v5.18;
use utf8;
use Object::Tiny qw(core);

use Jabbot;
use Net::Delicious;
use Regexp::Common qw/URI/;

sub can_answer {
    my ($self, $message) = @_;
    my $text = $message->{body};

    if ($text =~ /^(?:!d(?:elicious)?) +($RE{URI}{HTTP})(?: +tags:(.+?))?$/i) {
        $self->{url} = $1;
        $self->{tags} = $2;
        return 1;
    }
    return 0;
}

sub answer {
    my ($self, $message) = @_;
    my $text = $message->{body};

    return unless $self->{url};

    my $reply = "Posting failed due to alien invasion.";

    say "HUH";

    if ($self->post_to_delicious($self->{url})) {
        $reply = "Yummy.";
    }

    return { reply => $reply,  confidence => 0.9 };
}

sub post_to_delicious {
    my ($self, $url) = @_;

    my $config = Jabbot->config->{delicious};
    my $del = Net::Delicious->new({ user => $config->{username}, pswd => $config->{password}, debug => 1 });

    return $del->add_post({ url => $url, tags => "auto jabbot" });
}

1;
