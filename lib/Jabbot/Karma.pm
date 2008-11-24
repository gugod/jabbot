package Jabbot::Karma;
use Jabbot::Plugin -Base;

const class_id => 'karma';

sub process {
    my $msg = shift;
    my $s = $msg->text;
    my $reply;
    my $db = io->catfile($self->plugin_directory,"karma.db")->assert;
    if($s =~ /\S(?:\+\+|\-\-)(?:\s|\p{IsPunct}|$)/) {
        for my $k ($self->getKeywords($s)) {
            my ($word, $op) = @$k[0,1];
            if ( $op eq '++') {
                ($db->{$word})++;
            } elsif ( $op eq '--' ) {
                ($db->{$word})--;
            }
        }
        $reply = "ok, " . $msg->from;

        eval {
            tied(%{$db->tied_file})->sync;
        };
        if ($@) {
            print "??? sync failed\n";
        }
    } elsif ($s =~ /^karma\s+scoreboard\s*$/i) {
        $reply = join (", ", map {
            "$_(" . $db->{$_} .")"
        } grep {defined$_}(sort { $db->{$b} <=> $db->{$a} } keys %$db)[0..10]);
    } elsif ($s =~ /^negative\s+karma\s+scoreboard\s*$/i) {
        $reply = join (", ", map {
            "$_(" . $db->{$_} .")"
        } grep {defined$_} (sort { $db->{$a} <=> $db->{$b} } keys %$db)[0..10]);
    } elsif ($s =~ /^karma\s+(.+)\s*$/) {
        my $nword = lc($1);
        my $karma = $db->{$nword} || sub {
                    for(keys %$db) {
                        return $db->{$_} if($self->normalizeWord($_) eq $nword);
                    }
                    return 0; 
		}->();
        $reply = ($karma == 0)?"$1 has neutral karma":"$1 has karma of $karma";
    }
    $self->reply($reply,1);
}

use Regexp::Common qw/balanced/;
my $balanced_word = $RE{balanced}{-parens => '()[]{}'};

sub normalizeWord {
    my $str = lc(shift);

    if ($str =~ m/$balanced_word/) {
        substr($str,0,1) = "";
        substr($str,-1,1) = "";
    }

    return $str;
}

sub getKeywords {
    my $str = shift;
    my $word = qr/(?:
                      [^\s\p{IsPunct}]+?  |
                      $balanced_word
                  )/x;
    my $boundary = qr/(?:\s|\p{IsPunct}|$)/;

    my @words = ();

    while($str =~ m{($word)(\+\+|\-\-)$boundary}g) {
        push @words, [ $self->normalizeWord($1), $2 ];
    }

    return @words;
}

