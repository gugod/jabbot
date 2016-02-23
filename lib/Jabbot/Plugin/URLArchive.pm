package Jabbot::Plugin::URLArchive;
use v5.18;
use Object::Tiny;
use Regexp::Common qw/URI/;

use Jabbot::Memory;

sub can_answer {
    my ($self, $message) = @_;
    
    if ($message->{body} =~ /($RE{URI}{HTTP})/) {
        $self->{url} = $1;
        return 1;
    }
    return 0;
}

sub answer {
    my ($self, $text) = @_;
    my $ret = {
        body => "Cool",
        score => 0.5,
    };

    my $url = $self->{url} or return $ret;
    my $mem = Jabbot::Memory->new();
    $mem->set("url_archive", $url, scalar time);
    return $ret;
}

1;
