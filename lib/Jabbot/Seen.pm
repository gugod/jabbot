package Jabbot::Seen;
use Jabbot::Plugin -Base;

const class_id => 'seen';

sub process {
    my $msg = shift;
    my $nick = $msg->from;
    my $db = io->catfile($self->plugin_directory,"seen.db")->assert;
    my $now = time;
    my $reply;
    if($msg->text =~ /^seen\s+([^\s\?]+)\s*\?*/) {
        $reply = defined($db->{$1})?
            "$1 was seen on " . localtime($db->{$1}) :
            "I havn't seen $1 , $nick";
    }
    $db->{$nick} = time;
    $self->reply($reply,1);
}