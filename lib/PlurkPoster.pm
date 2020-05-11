package PlurkPoster;
use v5.26;
use Mojo::UserAgent;

sub new {
    my $class = shift;
    return bless { @_ }, $class;
}

sub login {
    my ($self) = @_;
    $self->{ua} = Mojo::UserAgent->new;

    my $tx = $self->{ua}->get('https://www.plurk.com/login');
    die "failed 1" if $tx->result->is_error;

    my $login_token = $tx->result->dom->at("input[name=login_token]")->attr("value");

    $tx = $self->{ua}->post(
        'https://www.plurk.com/login',
        form => {
            nick_name   => $self->{username},
            password    => $self->{password},
            login_token => $login_token
        }
    );

    die "failed 2" if $tx->result->is_error;

    return $self;
}

sub post {
    my ($self, $content) = @_;
    my $ua = $self->{ua};

    my @content;
    if ( length($content) < 360 ) {
        @content = ($content);
    }
    else {
        my $pieces = int(length($content) / 340);
        for (0 .. $pieces) {
            push @content, substr($content, 340 * $_, 340);
        }
        for (1..$#content-1) {
            $content[$_] = "... $content[$_] ...";
        }
        $content[0] .= "...";
        $content[-1] = "... $content[-1]";
    }

    my $text = shift @content;
    $text .= " $self->{hashtag}" if $self->{hashtag};

    my $tx = $ua->get('https://www.plurk.com/m');
    my $res = $tx->result;
    die "failed 3" if $res->is_error;

    my $user_id = $res->dom->at("input[name=user_id]")->attr("value");
    my $language = $res->dom->at("input[name=language]")->attr("value");
    my $form_token = $res->dom->at("input[name=form_token]")->attr("value");

    $tx = $ua->post('https://www.plurk.com/m/' => form => {
        user_id => $user_id,
        language => $language,
        qualifier => ":",
        content =>  $text,
        form_token => $form_token,
    });
    die "failed 4\n".$tx->result->body if $tx->result->is_error;
    say ">>> $text";

    $tx = $ua->get('https://www.plurk.com/m/?mode=my');
    die "failed 5" if $tx->result->is_error;

    my $link_to_plurk = $tx->res->dom->at("div.plurk[data-pid]");
    my ($plurk_id) = $link_to_plurk->attr("data-pid");

    if (@content) {
        my $plurk_permaurl = "http://www.plurk.com/m/p/${plurk_id}";
        say "DEBUG: plurk = $plurk_permaurl";
        while (@content) {
            my $text = shift @content;

            $tx = $ua->get($plurk_permaurl);
            die "failed 5" if $tx->result->is_error;

            say "RE> $text";
            $tx = $ua->post("${plurk_permaurl}/#plurkbox" => form => {
                user_id => $user_id,
                language => "en",
                qualifier => ":",
                content => $text,
            });
            sleep 5;
            die "failed 6" if $tx->result->is_error;
        }
    }

    return $plurk_id;
}

1;
