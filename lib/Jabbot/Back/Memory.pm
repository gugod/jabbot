package Jabbot::Back::Memory;
use common::sense;
use Giddy;
use Jabbot;

use AnyEvent;
use AnyEvent::MP;
use AnyEvent::MP::Global;
use YAML;

{
    my $db;

    sub db {
        return $db if $db;

        my $giddy = Giddy->new;
        my $db_path = Jabbot->root . "/var/memory";

        $db = $giddy->get_database($db_path);

        return $db;
    }
}

sub run {
    configure profile => "jabbot-memory";
    grp_reg "jabbot-memory", rcv port,
        get => sub {
            my ($collection, $key, $reply_port) = @_;
            return unless $collection && $key && $reply_port;

            my $co = db->get_collection($collection);
            my $doc = $co->find_one($key);

            snd $reply_port, $doc;
        },

        set => sub {
            my ($collection, $key, $value) = @_;
            return unless $collection && $key && defined($value);

            my $co = db->get_collection($collection);

            if ($co->find_one($key)) {
                $co->update($key, $value);
            }
            else {
                $co->insert($key, $value);
            }

            db->commit("memorize: ${collection}.${key}");
        };

    AE::cv->recv;
}

1;

