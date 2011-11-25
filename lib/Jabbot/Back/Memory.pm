package Jabbot::Back::Memory;
use v5.12;
use common::sense;
use Giddy;
use Jabbot;

use AnyEvent;
use AnyEvent::MP;
use AnyEvent::MP::Global;
use YAML;

sub db {
    state $db;

    return $db if defined $db;

    my $giddy = Giddy->new;
    my $db_path = Jabbot->root->subdir("var", "memory");

    $db = $giddy->get_database("$db_path");

    return $db;
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
        },

        update => sub {
            my ($collection, $query, $object, $options) = @_;
            return unless $collection && $query && defined($object);

            my $co = db->get_collection($collection);

            if ($co->find_one($query)) {
                $co->update($query, $object, $options);
            }
            else {
                $co->insert($query, {});
                db->commit;

                $co->update($query, $object, $options);
            }

            db->commit;
        };

    AE::cv->recv;
}

1;
