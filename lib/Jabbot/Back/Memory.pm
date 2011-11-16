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
            my ($collection, $key) = @_;
            return unless $collection && $key;

            my $co = db->get_collection($collection);
            return $co->find_one({ _name => $key });
        },
        set => sub {
            my ($collection, $key, $value) = @_;
            say YAML::Dump(\@_);
            return unless $collection && $key && defined($value);

            my $co = db->get_collection($collection);
            $co->insert($key, $value);
            return 1;
        };

    AE::cv->recv;
}

1;

