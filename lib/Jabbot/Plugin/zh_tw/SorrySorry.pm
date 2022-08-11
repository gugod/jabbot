package Jabbot::Plugin::zh_tw::SorrySorry;
use v5.36;
use utf8;
use Encode qw(decode_utf8);
use Object::Tiny qw(core);

sub can_answer {
    my ($self, $message) = @_;
    my $text = $message->{body};

    return 0.5 if $text =~ m{(
                                 對不起 | 道歉
                                 [!！]{2,}+ |
                                 可惡 | 混蛋 | 雜(碎｜種) |
                                 靠(你|夭) |
                                 豬 | 狗 | 雞 | 笨 |
                                 (打|踢|踩|踹|幹) 你 |
                                 punch |
                                 (fu|ki)ck
                             )}x;
    return 0;
}

sub answer {
    my ($self, $message) = @_;
    my $text = $message->{body};

    my @emoticons = qw{T_T ocz orz >_<" (>_<) (-_-)||| XD :P};

    my @answers = (
        "嗚嗚",
        "嗚嗚嗚",
        "嗚啊",
        "啊啊啊啊",
        "抱歉",
        "對不起...",
        "對不起啦",
        "我錯了",
        "我下次不敢了"
    );

    my $reply = $answers[rand($#answers)];

    for(1..6) {
        last if rand > 0.5;
        $reply .= " " . $answers[rand($#answers)];
    }

    $reply .= " ". $emoticons[rand($#emoticons)];

    return {
        body => $reply,
        score => 1
    }
}

1;
