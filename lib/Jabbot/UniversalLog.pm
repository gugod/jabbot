package Jabbot::UniversalLog;
use Jabbot::Plugin -Base;
use DBI;

const class_id => 'universal_log';

field dbh => {} => -init => q{$self->create_db};

sub create_db {
    io($self->plugin_directory)->mkpath;
    my $db = io->catfile($self->plugin_directory,'universal_log.db');

    my $db_exists = $db->exists;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db","","");

    return $dbh if ( $db_exists );

    $dbh->begin_work;
    $dbh->do(qq{CREATE TABLE universal_log ('id', 'created_at', 'channel', 'from', 'to', 'text');});
    $dbh->commit;
    return $dbh;
};

sub process {
    my $msg = shift;
    my $sql = "INSERT INTO universal_log ('created_at', 'channel', 'from', 'to', 'text') VALUES (?,?,?,?,?);";
    my $dbh = $self->dbh;
    my $st  = $dbh->prepare($sql);
    $dbh->begin_work;
    my $rv = $st->execute(time, $msg->channel, $msg->from, $msg->to, $msg->text );
    $dbh->commit;
    return;
}

