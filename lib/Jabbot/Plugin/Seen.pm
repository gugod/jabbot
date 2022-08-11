package Jabbot::Plugin::Seen;
use v5.36;
use Object::Tiny;
use Mojo::JSON qw(decode_json encode_json);

use Jabbot;
use Jabbot::Memory;
use Jabbot::Types qw(JabbotAuthorIdentifier);

sub can_answer {
    my ($self, $message) = @_;
    my $text = $message->{body};

    my $who = join("\t", $message->{network}, $message->{channel}, $message->{author});
    my $mem = Jabbot::Memory->new;
    $mem->set("seen", $who, encode_json({ time => time, message => $text }));

    if ($text =~ /^seen\s+(\S+)[\?\s]*$/) {
        my $whom = $1;
        if ( JabbotAuthorIdentifier()->check($whom) ) {
            $self->{whom} = join("\t", $message->{network}, $message->{channel}, $whom);
            return 1;
        }
    }

    return 0;
}

sub answer {
    my ($self, $message) = @_;
    my $text = $message->{body};

    my $whom = $self->{whom};

    my $mem = Jabbot::Memory->new;
    my $v = $mem->get("seen", $whom);
    return unless $v;

    my $seen = decode_json($v);

    return {
        body => "last seen at " . localtime($seen->{time}) . ", saying: $seen->{message}",
        score => 1
    }
}

1;
