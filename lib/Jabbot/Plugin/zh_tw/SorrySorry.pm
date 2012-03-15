package Jabbot::Plugin::zh_tw::SorrySorry;
use 5.012;
use utf8;
use encoding 'utf8';
use Jabbot::Plugin;

sub can_answer {
    my ($text) = @args;
    utf8::decode($text) unless utf8::is_utf8($text);

    my ($x) = $text =~ m{(
                            可惡 | 混蛋 | 雜(碎｜種) | 幹你 |
                            靠(你|夭) |
                            (打|踢|踩|踹) 你 |
                            punch |
                            (fu|ki)ck |

                    )}x;

    return $x;
}

sub answer {
    my ($text) = @args;
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

    for(1..2) {
        if (rand > 0.5) {
            $reply .= " " . $answers[rand($#answers)];
        }
    }

    $reply .= " ". $emoticons[rand($#emoticons)];

    return {
        content => $reply,
        confidence => 0.9
    }
}

1;
