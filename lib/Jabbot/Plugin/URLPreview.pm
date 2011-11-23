package Jabbot::Plugin::URLPreview;
use warnings;
use strict;
use Jabbot::Plugin;
use LWP::Simple;
use Web::Query;

sub can_answer {
    my ($text) = @args;
    return $text =~ m{https?://};  # match a url pattern ?
}

sub answer {
    my ($text) = @args;
    my ($url) = ($text =~ m{(https?://\S+)});

    # XXX: do something with metacpan or search.cpan.org ?
    my $title;
    wq($url)->find('title')
            ->each(sub {
                my $i = shift;
                $title = $_->text;
            });
    my $reply = sprintf '  %s => %s', $title, $url;
    return { content => $reply, confidence => 1 };
}

1;
