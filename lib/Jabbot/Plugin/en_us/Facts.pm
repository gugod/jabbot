package Jabbot::Plugin::en_us::Facts;
use common::sense;
use Object::Tiny;
use utf8;
use self;

my $question_mark = qr/(?:\?|？)/;

my @D2P = (
    qr/^(.+?)\s+=>\s+(.+)$/                           => \&_save_factpack,
    qr/^(?:what is\s)?\s*(.+?)\s*${question_mark}+$/i => \&_query,
    qr/^no,\s*(.+?)\s+is\s+(.+)$/i                    => \&_reset,
    qr/^forget\s+(.+)$/i                              => \&_forget,
    qr/^(.{1,64})\s+is\s+([^?]+)$/i                   => \&_save,
);

sub can_answer {
    my ($text) = @args;

    for my $i (0..$#D2P) {
        next if $i % 2;
        my ($regex, $sub) = @D2P[$i, $i+1];
        if ($text =~ m/$regex/) {
            $self->{matched} = [$1, $2];
            $self->{dispatch_to} = $sub;
            return 1;
        }
    }
}

sub answer {
    my $sub = $self->{dispatch_to};
    my $ans = $self->$sub(@{ $self->{matched} });

    return {
        content    => $ans,
        confidence => 1
    } if $ans
}

sub _save_factpack {
    my ($X, $Y) = @args;
    $self->_save($X, "<reply>$Y");
}

sub _save {
    my ($X, $Y) = @args;

    return if $X =~ / that|this|what|who|when|how /xi;

    my $orig = $self->db->{$X};

    if ($Y =~ s/^also\s+//i) {
        $orig = "" unless defined $orig;
        $orig =~ s/\.?$/, /;
        $orig .= $Y;

        $self->db->{$X} = $orig;
    }
    elsif (defined $orig) {
        return "But $X is $orig";
    }
    else {
        $self->db->{$X} = $Y;
        return "roger that"
    }
}

sub _reset {
    my ($X, $Y) = @args;

    $self->db->{$X} = $Y;

    "ok!";
}

sub _forget {
    my ($X) = @args;
    delete $self->db->{$X};

    return "What is $X ?";
}

sub _query {
    my ($X) = @args;
    return "" unless defined(my $r =  $self->db->{$X});

    utf8::decode($r);

    if ($r =~ s/^<reply>\s*//) {
        return $r;
    }

    return "$X is $r";
}

{
    use IO::All;
    io->catdir(Jabbot->root, "var", "plugins")->mkpath;

    my $db;
    sub db {
        return $db if $db;

        $db = io->catfile(Jabbot->root, "var", "plugins", "facts.db")->utf8->assert;
        $db->{__inited__} = time;
        return $db;
    }
}

1;
