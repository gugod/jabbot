package Jabbot::Plugin::zh_tw::Elizaish;
use v5.18;
use utf8;
use Object::Tiny qw(core);
use Jabbot::Util qw(bag_eq);
use Ref::Util qw( is_arrayref );

my @RULES = (
    [ qr/ 你好 | 早安 | 午安 | 晚安 | 安安 /x,
      'greeting' ],

    [ qr/ 我夢到 (?<thing>\p{Letter}+) /x,
      'dream' ],

    [ qr/ 我記得 (?<thing>\p{Letter}+) /x,
      'remember' ],

    [ qr/ (為何|為什麼|什麼是|有沒有|誰[有能會]|什麼時候|何時|怎麼樣|怎樣|在哪裡) /x,
      'ask_back' ],

    [ qr/ (\p{Han})不\1 /x,
      'ask_back' ],

    [ qr/ 好?[呢嗎]\s* [\?？]? \s* \z /x,
      'ask_back' ],

    [ qr/ 好像|或許|可能|應該|大概 /x,
      'perhaps' ],

    [ qr/ 對啊|沒錯|嗯 /x,
      'confirmed' ],

    [ qr/ 真是 (?<thing>\p{Letter}+) /x,
      'why_do_you_say_so' ],

    [ qr/ (?<verb>[看讀吃喝]) 了 (?<object>\p{Letter}+) /x,
      'ask_back_is_it_good' ],
    [ qr/ 好 (?<verb>[看吃喝玩]) \b /x,
      'it_is_nice' ],
    [ qr/ 不難 (?<verb> [看吃喝玩]) \b /x,
      'it_is_not_bad' ],
    [ qr/ 謝謝你?(?<tone>[喔啦])? /x,
      'you_are_welcome' ],

    [ qr/\A ([^你]*) 你 /x, 'you' ],

    # Generic
    [qr/\p{Han}/x,
     'nodding']
);

my %REACTIONS = (
    ask_back_is_it_good => ['好{{verb}}嗎？'],
    you_are_welcome     => ['不客氣', '不客氣{{tone}}'],
    it_is_nice          => ['太好了呢', '讚喔', '好喔'],
    it_is_not_bad       => ['不錯喔', '還不賴喔'],

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

    ask_back => [
        '為什麼這麼問呢',
        '這個問題讓你覺得有意思是嗎？',
        '你覺得呢？',
        '在你提出此問題時，心裡頭在想什麼？',
        '你有向其他人問過這個問題嗎',
    ],

    nodding => [
        '嗯嗯',
        '請繼續',
        '請多說一點',
        '我了解',
        '我能體會',
    ],

    you => [
        '我們不要一直講我的事，應該多聊你的事',
        '我們應該多聊你的事',
        '你現在心情如何？'
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
