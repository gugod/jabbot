package Jabbot::CPANAuthors;
use Jabbot::Plugin -Base;
use Parse::CPAN::Authors;
use LWP::Simple qw(get);
use Cache::File;
use Acme::CPANAuthors;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);

const class_id => 'cpanauthors';

sub process {
    my $msg = shift;
    my $nick = $msg->from;

    my $reply = '';
    # country
    if($msg->text =~ /^authors (?<COUNTRY>\w+)/ ) {
        my $country = ucfirst $+{COUNTRY};
        $country =~ s/^Taiwan$/Taiwanese/;  # patch
        my $acme_authors = Acme::CPANAuthors->new($country);  # taiwanese
        unless( $acme_authors ) {
            $reply= "there is no such module for $country";
        }

        # XXX: implement
        $reply = qq!  There are @{[  $acme_authors->count ]} in $country. They are !;
        $reply .= join( ',' , values %$acme_authors ) . ' ..etc';

    }
    # id
    elsif( $msg->text =~ /^author (?<AUTHOR_ID>\w+)$/ ) {
        my $author_id = uc( $+{AUTHOR_ID} );
        my $acme_authors = Acme::CPANAuthors->new;
        my @authors = Acme::CPANAuthors->look_for($author_id);
         for my $author ( @authors) {
            $reply .= sprintf("%s (%s) belongs to %s.\n",
                $author->{id}, $author->{name}, $author->{category});
         }
    }
    $self->reply($reply,1);
}

