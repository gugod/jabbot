package Jabbot::Facts;
use Jabbot::Plugin -Base;

const class_id => 'facts';

field db => {}, -init => q{$self->_load};

sub process {
    my $msg = shift;

    my $r = $self->react_to($msg);

    $r =~ s{ \$who }
           { $msg->from }xe;

    $self->reply($r, defined($r) );
}

my %D2P = (
    qr/(.+?)\s+is\s+(.+)/i        => \&_save,
    qr/no,\s*(.+?)\s+is\s+(.+)/i  => \&_reset,
    qr/forget\s+(.+)/i            => \&_forget,
    qr/(?:what is\s+)?(.{1,64})\s*\?+/           => \&_query,
);

sub react_to {
    my $msg = shift;
    my $text = $msg->text;

    for my $regex (keys %D2P) {
        next unless $text =~ m/$regex/;

        return $D2P{$regex}->($self, $1, $2);
    }
}

sub _save {
    my ($X, $Y) = @_;
    my $orig = $self->db->{$X};

    if ($Y =~ /^also\s+(.+)$/) {
        $orig = "" unless defined $orig;
        $orig =~ s/\.?$/, /;
        $orig .= $Y;
    }

    if (defined $orig) {
        return "But $X is something else...";
    }

    $self->db->{$X} = $Y;
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
