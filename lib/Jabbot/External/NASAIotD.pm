package Jabbot::External::NASAIotD;
use v5.36;

use Object::Tiny;
use constant FEED_URL => 'https://www.nasa.gov/rss/dyn/lg_image_of_the_day.rss';

use Mojo::UserAgent;

sub photos {
    my $ua = Mojo::UserAgent->new();
    my $res = $ua->get( FEED_URL )->result;
    return [] unless $res->is_success;

    my @photos = $res->dom->find("item")->map(
        sub {
            my $el = $_;
            my $title = $el->at("title")->all_text;
            my $photo_page_url = $el->at("link")->all_text;
            my $enclosure_url = $el->at("enclosure")->attr("url");
            return {
                title => $title,
                author => 'NASA',
                photo_page_url => $photo_page_url,
                enclosure_url => $enclosure_url,
            }
        }
    )->each;

    return \@photos;
}

1;
