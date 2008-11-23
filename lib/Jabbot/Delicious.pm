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
    print $msg->text, "\n";
    if ($msg->text =~ /^spread +($RE{URI}{HTTP})(?: +tags:(.+?))?$/i) {
        my $del = Net::Delicious->new({ user => $config->{username}, pswd => $config->{password} });

        my $res = $del->add_post({
            url => $1,
            tags => "for:$msg_from " . ($2||"")
        });

        if($res) {
            $self->reply("that's delicious, $msg_from", 1);
        }
        else {
            $self->reply("something wrong with delicious, $msg_from", 1);
        }
    }
}
