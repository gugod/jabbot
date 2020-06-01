package Jabbot::Plugin::zh_tw::Elizaish;
use v5.18;
use utf8;
use Object::Tiny qw(core);
use Jabbot::Util qw(bag_eq);
use Ref::Util qw( is_arrayref );

my @RULES = (
    [ qr/ 你好 | 早安 | 午安 | 晚安 | 安安 /x,
      'greeting' ],

    [ qr/ 我夢到 (?<thing>.+) /x,
      'dream' ],

    [ qr/ 我記得 (?<thing>.+) /x,
      'remember' ],

    [ qr/ 好像|或許|可能|應該|大概 /x,
      'perhaps' ],

    [ qr/ 真是 (?<thing>\p{Han}+) /x,
      'why_do_you_say_so' ],

    [ qr/ (?<verb>[看讀吃喝]) 了 (?<object>.+) /x,
      'ask_back_is_it_good' ],
    [ qr/ 好 (?<verb>[看吃喝玩]) (！|\z) /x,
      'it_is_nice' ],
    [ qr/ 不難 (?<verb> [看吃喝玩]) (！|。|\z) /x,
      'it_is_not_bad' ],
    [ qr/ 謝謝你?(?<tone>[喔啦])? /x,
      'you_are_welcome' ],
    # Generic
    [qr/./x,
     'generic_neutral']
);

my %REACTIONS = (
    ask_back_is_it_good => ['好{{verb}}嗎？'],
    you_are_welcome     => ['不客氣', '不客氣{{tone}}'],
    it_is_nice          => ['太好了呢'],
    it_is_not_bad       => ['不錯喔'],
    generic_neutral     => ['嗯嗯', '喔喔'],

    greeting => [
        '你好。最近過得如何？',
        '哈囉。最近好嗎？',
        '嘿，好久不見',
        '呦，我是個電腦程式',
        '有什麼讓你覺得心煩的事情嗎？'
    ],

    remember => [
        '你常常想起{{thing}}嗎',
        '你還記得哪些事情呢',
        '為何突然想起{{thing}}呢',
        '{{thing}}，有讓你聯想起其他什麼事情嗎',
    ],

    dream => [
        '你常常做這個夢嗎',
        '你以前做過這個夢嗎',
        '你真的夢到{{thing}}嗎',
        '在這個夢裡面有出現其他人嗎',
    ],

    perhaps => [
        '你好像很不確定',
        '為何使用不確定的語氣呢',
        '真的假的',
    ],

    why_do_you_say_so => [
        '怎麼說呢？',
        '為何這麼說呢？',
        '為何說{{thing}}呢？',
    ],
);

sub can_answer {
    my ($self, $message) = @_;

    my $body = $message->{body};
    for my $rule (@RULES) {
        my $re = $rule->[0];
        if (my @matched = $body =~ m/($re)/) {
            $self->{__matched} = \@matched;
            $self->{__matched_vars} = { %+ };
            $self->{__rule} = $rule;
            return 1;
        }
    }
    return 0;
}

sub answer {
    my ($self, $message) = @_;

    my @reactions = grep {
        my @wanted = $_ =~ m/\{\{([a-z]+)\}\}/g;
        my @got = grep { defined($self->{__matched_vars}{$_}) } @wanted;
        bag_eq(\@got, \@wanted);
    } @{$REACTIONS{ $self->{__rule}->[1] }};

    my $res = $reactions[rand(@reactions)];

    for my $var (keys %{$self->{__matched_vars}}) {
        $res =~ s/\{\{$var\}\}/$self->{__matched_vars}{$var}/g;
    }

    return {
        body  => $res,
        score => 0.8 * ( length($self->{__matched}[0]) / length($message->{body})) ,
    }
}

1;
