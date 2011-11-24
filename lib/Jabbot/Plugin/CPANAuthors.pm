package Jabbot::CPANAuthors;
use Jabbot::Plugin;
use Acme::CPANAuthors;
use WWW::Shorten qw(TinyURL);
use Cache::Memory;

sub can_answer {
    my ($text) = @_;
    return 1 if $text =~ /author/;
}

sub answer {
    my ($text) = @_;

    my $reply = '';
    # country
    if($text =~ /^(?<COUNTRY>\w+)\s+authors/ ) {
        my $country = ucfirst $+{COUNTRY};
        $country =~ s/^Taiwan$/Taiwanese/;  # patch
        my $acme_authors = Acme::CPANAuthors->new($country);  # taiwanese
        unless( $acme_authors ) {
            $reply= "there is no such module for $country";
        }

        $reply = qq!  There are @{[  $acme_authors->count ]} in $country. They are !;
        $reply .= join( ', ' , map { $_ } keys %$acme_authors ) . ' ..etc';
        return { content => $reply };
    }
    # id
    elsif( $text =~ /^author (?<AUTHOR_ID>\w+)$/ ) {
        my $author_id = uc( $+{AUTHOR_ID} );

        my $cache = Cache::Memory->new(
            namespace => 'MyNamespace',
            default_expires => '10 days',
        );

        my $reply = $cache->get( $author_id );
        return { content => $reply };

        my @authors = Acme::CPANAuthors->look_for($author_id);
        for my $author ( @authors) {

            $reply .= sprintf("%s (%s) belongs to %s. ",
                $author->{id}, $author->{name}, $author->{category});

            my $acme_authors = Acme::CPANAuthors->new( $author->{category} );
            my @dists = $acme_authors->distributions( $author->{id} );

            $reply .= sprintf(" %s has %d dists." , $author->{id} , scalar @dists );

            my $url = makeashorterlink( $acme_authors->avatar_url( $author->{id} ) );
            $reply .= sprintf(" %s looks like this: %s", $author->{id} , $acme_authors->avatar_url( $author->{id} ) );
        }
        $cache->get( $author_id , $reply );
    }
    return { content => $reply };
}

1;
