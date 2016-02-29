package PlurkPoster;
use v5.14;
use Data::Dumper;
use Mojo::UserAgent;

sub new {
    my $class = shift;
    return bless { @_ }, $class;
}

sub login {
    my ($self) = @_;
    $self->{ua} = Mojo::UserAgent->new;
    $self->{ua}->on(
        "start",
        sub {
            my ($ua, $tx) = @_;
            my $headers = $tx->req->headers;
            $headers->remove("Accept-Encoding");
            $headers->header("User-Agent", "Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420+ (KHTML, like Gecko) Version/3.0 Mobile/1A543 Safari/419.3");
        }
    );

    my $tx = $self->{ua}->get('https://www.plurk.com/m/login');
    die "failed 1" unless $tx->success;

    $tx = $self->{ua}->post('https://www.plurk.com/m/login' => form => { username => $self->{username}, password => $self->{password} });
    die "failed 2" unless $tx->success;

    return $self;
}

sub post {
    my ($self, $content) = @_;
    my $ua = $self->{ua};

    my @content;
    if ( length($content) < 120 ) {
        @content = ($content);
    }
    else {
        my $pieces = int(length($content) / 120);
        for (0 .. $pieces) {
            push @content, substr($content, 120 * $_, 120);
        }
        for (1..$#content-1) {
            $content[$_] = "... $content[$_] ...";
        }
        $content[0] .= "...";
        $content[-1] = "... $content[-1]";
    }

    my $text = shift @content;
    $text .= " $self->{hashtag}" if $self->{hashtag};

    my $tx = $ua->get('http://www.plurk.com/m/');
    die "failed 3" unless $tx->success;

    my $user_id = $tx->res->dom->find("input[name=user_id]")->first->attr("value");

    $tx = $ua->post('http://www.plurk.com/m/' => form => {
        user_id => $user_id,
        language => "en",
        qualifier => ":",
        content =>  $text,
    });
    die "failed 4" unless $tx->success;
    say ">>> $text";

    $tx = $ua->get('http://www.plurk.com/m/?mode=my');
    die "failed 5" unless $tx->success;

    my $link_to_plurk = $tx->res->dom->find("div.plurk[data-pid]")->first;
    my ($plurk_id) = $link_to_plurk->attr("data-pid");
    my $plurk_permaurl = "http://www.plurk.com/m/p/${plurk_id}";

    say "DEBUG: plurk = $plurk_permaurl";
    while (@content) {
        my $text = shift @content;

        $tx = $ua->get($plurk_permaurl);
        die "failed 5" unless $tx->success;

        say "RE> $text";
        $tx = $ua->post("${plurk_permaurl}/#plurkbox" => form => {
            user_id => $user_id,
            language => "en",
            qualifier => ":",
            content => $text,
        });
        sleep 5;
        die "failed 6" unless $tx->success;
    }

    return $plurk_id;
}

1;
