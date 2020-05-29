package Jabbot::External::FlickrPublicFeed;
use strict;
use warnings;

use Object::Tiny;
use constant FEED_URL => 'https://www.flickr.com/services/feeds/photos_public.gne';

use Mojo::UserAgent;

sub photos {
    my $ua = Mojo::UserAgent->new();
    my $res = $ua->get( FEED_URL )->result;
    return [] unless $res->is_success;

    my @photos = $res->dom->find("entry")->map(
        sub {
            my $el = $_;
            my $title = $el->at("title");
            my $author = $el->at("author > name")->all_text;
            my $photo_page_url = $el->at("link[rel=alternate]")->attr("href");
            my $enclosure_url = $el->at("link[rel=enclosure]")->attr("href");
            return {
                title => $title,
                author => $author,
                photo_page_url => $photo_page_url,
                enclosure_url => $enclosure_url,
            }
        }
    )->each;

    return \@photos;
}

1;
