package Jabbot::Delicious;
use Jabbot::Plugin -Base;

const class_id => 'delicious';

use Net::Delicious;
use Regexp::Common qw/URI/;
use URI::Title qw( title );

sub process {
    my $config = $self->hub->config->{delicious};
    return if (!$config->{username} || !$config->{password});

    my $msg = shift;
    my $msg_from = $msg->from;

    if ($msg->text =~ /^(?:spread|\+d|delicious) +($RE{URI}{HTTP})(?: +tags:(.+?))?$/i) {
        my ($url,$tags) = ($1,$2);

        $tags ||= "";

        my $res = $self->post_to_delicious($url, "$tags by_${msg_from}");

        if($res) {
            $self->reply("that's delicious, $msg_from", 1);
        }
        else {
            $self->reply("something wrong with delicious, $msg_from", 1);
        }
    }
    elsif ($msg->text =~ /($RE{URI}{HTTP})/) {
        $self->post_to_delicious($1);
    }
}

sub post_to_delicious {
    my ($url, $given_tags) = @_;
    $given_tags ||= "";

    my $config = $self->hub->config->{delicious};
    my $del = Net::Delicious->new({ user => $config->{username}, pswd => $config->{password} });

    my $title = title($url) || "";
    my $auto_tags = join " ", split /\W/, "$url $title";

    my $res = $del->add_post({ url => $url, tags => "$given_tags $auto_tags", description => $url });
    return $res;
}
