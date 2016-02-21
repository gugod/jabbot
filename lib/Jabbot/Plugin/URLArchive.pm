package Jabbot::Plugin::URLArchive;
use v5.18;
use Object::Tiny qw(core);
use Regexp::Common qw/URI/;

use Jabbot::Memory;

sub can_answer {
    my ($self, $text) = @_;
    if ($text =~ /($RE{URI}{HTTP})/) {
        my $url = $1;
        my $mem = Jabbot::Memory->new();
        $mem->set("url_archive", $url, scalar time);
    }
    return 0;
}

sub answer {
    return {
        body => "",
        score => 0,
    };
}

1;
