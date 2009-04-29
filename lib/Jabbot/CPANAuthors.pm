package Jabbot::CPANAuthors;
use Jabbot::Plugin -Base;
use Acme::CPANAuthors;
use WWW::Shorten qw(TinyURL);
use Cache::Memory;

const class_id => 'cpanauthors';


sub process {
    my $msg = shift;
    my $nick = $msg->from;

    my $reply = '';
    # country
    if($msg->text =~ /^(?<COUNTRY>\w+)\s+authors/ ) {
        my $country = ucfirst $+{COUNTRY};
        $country =~ s/^Taiwan$/Taiwanese/;  # patch
        my $acme_authors = Acme::CPANAuthors->new($country);  # taiwanese
        unless( $acme_authors ) {
            $reply= "there is no such module for $country";
        }

        $reply = qq!  There are @{[  $acme_authors->count ]} in $country. They are !;
        $reply .= join( ', ' , map { $_ } keys %$acme_authors ) . ' ..etc';

    }
    # id
    elsif( $msg->text =~ /^author (?<AUTHOR_ID>\w+)$/ ) {
        my $author_id = uc( $+{AUTHOR_ID} );

        my $cache = Cache::Memory->new(
            namespace => 'MyNamespace',
            default_expires => '10 days',
        );

        my $reply = $cache->get( $author_id );
        return $self->reply( $reply, 1 ) if ($reply);

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
    $self->reply($reply,1);
}

