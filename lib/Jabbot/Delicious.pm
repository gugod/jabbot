package Jabbot::Delicious;
use Jabbot::Plugin -Base;

const class_id => 'delicious';

use Net::Delicious;
use Regexp::Common qw/URI/;

sub process {
    my $config = $self->hub->config->{delicious};
    return if (!$config->{username} || !$config->{password});

    my $msg = shift;
    my $msg_from = $msg->from;
    if ($msg->text =~ /^(?:spread|\+d|delicious) +($RE{URI}{HTTP})(?: +tags:(.+?))?$/i) {
        my ($url,$tags) = ($1,$2);
        my $del = Net::Delicious->new({
            user => $config->{username},
            pswd => $config->{password},
            debug => 1
        });

        print "!! Posting $url to delicious\n";


        my $auto_tags = join " ", split /\W/, $url;

        my $res = $del->add_post({
            url => $url,
            tags => "$auto_tags by_${msg_from} " . ($tags||""),
            description => $url,
        });

        if($res) {
            $self->reply("that's delicious, $msg_from", 1);
        }
        else {
            $self->reply("something wrong with delicious, $msg_from", 1);
        }
    }
}
