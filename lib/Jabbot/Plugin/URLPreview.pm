package Jabbot::Plugin::URLPreview;
use v5.18;
use utf8;
use Object::Tiny qw(core);

use Web::Query;
use Try::Tiny;
use Regexp::Common qw/URI/;

sub can_answer {
    my ($self, $message) = @_;
    my $text = $message->{body};

    if ($text =~ /($RE{URI}{HTTP})/) {
        $self->{matched} = $1;
        return 1;
    }
    return 0;
}

sub answer {
    my ($self, $message) = @_;
    my $text = $message->{body};

    my ($url) = $self->{matched};

    # TODO: 
    #  * do something with metacpan or search.cpan.org ?
    #  * consider circumstances of large file or non-html content.
    #     my $request = HTTP::Request->new(HEAD => $url);
    #     my $response = $ua->request($request);
    my $title;
    try {
        wq($url)->find('title')
                ->each(sub {
                    my $i = shift;
                    $title = $_->text;
                });
    } catch {

    };

    if (defined($title)) {
        my $reply = sprintf '=>  %s', $title;
        return { body => $reply, score => 1 };
    }
}

1;
