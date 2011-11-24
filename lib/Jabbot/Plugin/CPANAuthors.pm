package Jabbot::Plugin::CPANAuthors;
use Jabbot;
use Jabbot::Plugin;
use Acme::CPANAuthors;
use WWW::Shorten qw(TinyURL);
use Cache::Memory;

sub can_answer {
    my ($text, $message) = @args;
    return 1 if $text =~ /!cpan\s+/i;
}


sub _get_country_authors {
    my ($country) = @args;
    $country = ucfirst $country;
    $country =~ s/^Taiwan$/Taiwanese/;  # patch
    my $acme_authors = Acme::CPANAuthors->new($country);  # taiwanese
    return unless  $acme_authors ;
}



sub answer {
    my ($text, $message) = @args;
    $text =~ s{^\w+:\s*!cpan\s+}{};

    my $reply = '';
    # country
    if($text =~ /^(?<COUNTRY>\w+)\s+authors/ ) {
        my $country = ucfirst $+{COUNTRY};
        my $acme_authors = $self->_get_country_authors( $country );
        return { content => "there is no such module for $country" } unless $acme_authors;

        $reply = qq!There are @{[  $acme_authors->count ]} in $country. They are !;
        $reply .= join( ', ' , map { $_ } keys %$acme_authors ) . ' ..etc';
        return { content => $reply , confidence => 1 };
    }
    # id
    elsif( $text =~ /^author\s+(?<AUTHOR_ID>\w+)/ ) {
        my $author_id = uc( $+{AUTHOR_ID} );

        my $cache = Cache::Memory->new(
            namespace => 'cpan_authors',
            default_expires => '10 days',
        );

        my $reply = $cache->get( $author_id );
        return { content => $reply , confidence => 1 } if $reply;

        my @authors = Acme::CPANAuthors->look_for($author_id);

        return { content => 'author not found' ,confidence => 1 } unless @authors;

        for my $author ( @authors) {

            $reply .= sprintf("%s (%s) belongs to %s. ",
                $author->{id}, $author->{name}, $author->{category});

            my $acme_authors = Acme::CPANAuthors->new( $author->{category} );
            my @dists = $acme_authors->distributions( $author->{id} );

            $reply .= sprintf(" %s has %d dists." , $author->{id} , scalar @dists );

            my $url = makeashorterlink( $acme_authors->avatar_url( $author->{id} ) );
            $reply .= sprintf(" %s looks like this: %s", $author->{id} , $acme_authors->avatar_url( $author->{id} ) );
            $reply .= "\n";
        }
        $cache->set( $author_id , $reply );
        return { content => $reply , confidence => 1 };
    }
}

1;
