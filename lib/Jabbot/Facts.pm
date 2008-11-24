package Jabbot::Facts;
use Jabbot::Plugin -Base;

const class_id => 'facts';

field db => {}, -init => q{$self->_load};

sub process {
    my $msg = shift;

    my $r = $self->react_to($msg);

    $r =~ s{ \$who }
           { $msg->from }xe;

    # manually close db handle since now that we have different frontends running,
    # db should be reloaded everytime this sub is invoked.
    $self->db(undef);
    $self->reply($r, defined($r) );
}

my $question_mark = qr/(?:\?|？)/;

my @D2P = (
    qr/^(.+?)\s+=>\s+(.+)$/                           => \&_save_factpack,
    qr/^(?:what is\s)?\s*(.+?)\s*${question_mark}+$/i => \&_query,
    qr/^no,\s*(.+?)\s+is\s+(.+)$/i                    => \&_reset,
    qr/^forget\s+(.+)$/i                              => \&_forget,
    qr/^(.+?)\s+is\s+([^?]+)$/i                       => \&_save,
);

sub react_to {
    my $msg = shift;
    my $text = $msg->text;

    my $i = 0;
    for my $i (0..$#D2P) {
        next if $i % 2;
        my ($regex, $sub) = @D2P[$i, $i+1];
        if ($text =~ m/$regex/) {
            return $sub->($self, $1, $2);
        }
    }

    tied(%{$self->db->tied_file})->sync;
}

sub _save_factpack {
    my ($X, $Y) = @_;
    $self->_save($X, "<reply>$Y");
}

sub _save {
    my ($X, $Y) = @_;
    my $orig = $self->db->{$X};

    if ($Y =~ s/^also\s+//i) {
        $orig = "" unless defined $orig;
        $orig =~ s/\.?$/, /;
        $orig .= $Y;

        $self->db->{$X} = $orig;
    }
    elsif (defined $orig) {
        return "But $X is something else...";
    }
    else {
        $self->db->{$X} = $Y;
    }
    return 'ok, $who';
}

sub _reset {
    my ($X, $Y) = @_;

    $self->db->{$X} = $Y;
    "ok!";
}

sub _forget {
    my ($X) = @_;
    delete $self->db->{$X};
    "What is $X ?";
}

sub _query {
    my ($X) = @_;
    return "" unless defined(my $r =  $self->db->{$X});

    if ($r =~ s/^<reply>\s*//) {
        return $r;
    }
    return "$X is $r";
}

sub _load {
    io($self->plugin_directory)->mkpath;
    my $db = io->catfile($self->plugin_directory,'main.db')->utf8->assert;
    $self->db($db);
    return $db;
}
