package Jabbot::Plugin::Uni;
use v5.18;
use Object::Tiny qw(core);

sub can_answer {
    my ($self, $message) = @_;

    if ($message->{body} =~ m/\A \s* !uni \s+ (?<query>.+) \s* \z/x) {
        $self->{query} = $+{query};
        return 1;
    }

    return 0;
}

sub answer {
    my ($self, $message) = @_;

    my $query = $self->{query};

    my @terms = split /\s+/, $query;
    my $chars = chars_by_name(\@terms);

    if (@$chars) {
        if (@$chars > 100) {
            my $n = @$chars - 100;
            return {
                body => join(" ", @$chars[0..24], "... (and $n more)"),
                score => 1,
            }
        } else {
            return {
                body => join(" ", @$chars),
                score => 1,
            }
        }
    } else {
        return {
            body => "Not found: $query",
            score => 1,
        }
    }
}

sub chars_by_name {
    my ($terms) = @_;

    state $corpus //= do {
        my $x = require 'unicore/Name.pl';
        die "On NO" if $x eq '1';
        [ split /\cJ/, $x ];
    };

    my @chars;
    my %seen;
    LINE: for my $line (@$corpus) {
        my $i = index($line, "\t");
        next if rindex($line, " ", $i) >= 0;

        my $name = substr($line, $i+1);
        my $ord  = hex substr($line, 0, $i);

        for (@$terms) {
            next LINE unless $name =~ /\b\Q$_\E\b/i;
        }

        my $c = chr hex substr $line, 0, $i;
        next if $seen{$c}++;
        push @chars, chr hex substr $line, 0, $i;
    }

    return \@chars;
}


1;
