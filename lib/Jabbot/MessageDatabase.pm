package Jabbot::MessageDatabase;
use Jabbot::Plugin -Base;
use DBI;

const class_id => 'message_database';

sub dbfile {
    my $dbf = io->catfile($self->plugin_directory,'message.sqlite');
    unless($dbf->exists) {
        $self->dbinit($dbf->name);
    }
}

sub db_connect {
    my $dbfile = $self->dbfile;
    DBI->connect("dbi:SQLite:dbname=$dbfile","","");
}

sub dbinit {
    my $dbfile = shift;
    io($self->plugin_directory)->mkdir;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","",
                           { RaiseError => 1, AutoCommit => 1});
    $dbh->do('CREATE TABLE messages (id,text,channel,to)');
    $dbh->disconnect;
}

sub process {
    $self->reply('');
}

sub append {
    my $msg;
    my $dbh = $self->db_connect;
    my $sth = $dbh->prepare("INSERT INTO messages values(?,?,?,?)");
    my $msg_id = $dbh->do("SELECT MAX(id) FROM messages");
    $msg_id++;
    $sth->execute(undef,$msg->text,$msg->channel,$msg->to);
    $sth->finish;
    $dbh->disconnect;
}

sub next {
}
