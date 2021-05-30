package Jabbot::Front::IRC;
use Mojolicious::Lite;

use Jabbot;
use Jabbot::RemoteCore;

use Encode qw(decode_utf8);

use IRC::Utils ();
use Mojo::JSON qw(decode_json);
use Mojo::IRC;
use Mojo::IOLoop;
use Mojo::IOLoop::Delay;

my $IRC_CLIENTS = {};

sub init_irc_client {
    my ($config) = @_;
    state $jabbot = Jabbot::RemoteCore->new;

    my $nick = $config->{nick};

    my $irc = Mojo::IRC->new(
        nick => $config->{nick},
        user => $config->{nick},
        server => $config->{server} . ":" . $config->{port},
    );
    $irc->tls({}) if $config->{tls};

    $irc->on(
        error => sub {
            my ($self, $message) = @_;
            p($message);
            Mojo::IOLoop->timer( 10 => sub { $irc->connect(sub {}) });
        });

    $irc->on(
        irc_join => sub {
            my($self, $message) = @_;
            say "yay! i joined $message->{params}[0]";
        });

    $irc->on(
        irc_privmsg => sub {
            my($self, $message) = @_;
            my $from_nick = IRC::Utils::parse_user($message->{prefix});
            return unless $from_nick;
            return if $from_nick =~ /${nick}_*/;
            my ($channel, $message_text) = @{$message->{params}};
            my ($message_text_without_my_nick_name) = $message_text =~ m/\A ${nick} [,:\s]+ (.+) \z/ixmas;
            if (!$message_text_without_my_nick_name && ($message_text =~ m/\A \<(\w+)\> \s ${nick} [,:\s]+ (.+) \z/ixmas )) {
                $from_nick = $1;
                $message_text_without_my_nick_name = $2;
            }
            return unless $message_text_without_my_nick_name;
            my $answer = $jabbot->answer({
                body    => $message_text_without_my_nick_name,
                author  => $from_nick,
                network => "irc",
                channel => "$channel",
            });
            if (my $reply_text = $answer->{body}) {
                $self->write(PRIVMSG => $channel, ":${from_nick}: $reply_text", sub {});
            }
        });

    $irc->on(
        irc_rpl_welcome => sub {
            for (@{$config->{channels}}) {
                my ($channel, $key) = ref($_) ? @$_ : ($_);
                $channel = "#${channel}" unless index($channel, "#") == 0;
                say "-- connected, join $channel";
                $irc->write(join => $channel, $key||());
            }});

    $irc->register_default_event_handlers;
    $irc->connect(sub {});
    return $irc;
}

get '/' => sub {
    my $c = shift;
    $c->render(json => {
        name     => "jabbot-ircbotd",
    });
};

post '/' => sub {
    my $c = shift;
    my $req = $c->req->json;

    my $network = $req->{network};
    my $channel = $req->{channel};
    my $text = $req->{text};

    my $error;
    my $response = {};

    my $irc_client = $IRC_CLIENTS->{$network};
    if ( $irc_client ) {
        $irc_client->write(PRIVMSG => $channel, ":${text}");
    } else {
        $error = "Unknown network: $network";
    }
    if ($error) {
        $response->{error} = $error;
    }
    $c->render(json => $response);
};

my $networks = Jabbot->config->{ircbot}{networks};
for (keys %$networks) {
    my $config = $networks->{$_};
    $config->{name} = $_;
    $config->{nick} ||= (Jabbot->config->{nick} || "jabbot_$$");
    say "--- Init IRC Client for network $_";
    $IRC_CLIENTS->{$_} = init_irc_client($config);
}

app->start;
