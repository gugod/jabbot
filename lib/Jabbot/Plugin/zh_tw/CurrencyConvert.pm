package Jabbot::Plugin::zh_tw::CurrencyConvert;
use Jabbot::Plugin;
use HTTP::Request::Common qw(GET);
use LWP::UserAgent;
use Encode;
use List::Util qw(shuffle);
use utf8;
use encoding 'utf8';
use Mojo::DOM;
use Try::Tiny;

my %cname = (USD => "美金", TWD => "新台幣", JPY => "日圓", HKD => "港幣",
             MCY => "人民幣", GBP => "英鎊", EUR => "歐元", CAD => "加拿大元",
             AUD => "澳元", THB => "泰銖", SGD => "新加坡元", KOW => "南韓圜",
             IDR => "印尼盾", MYR => "馬來西亞幣", PHP => "菲律賓披索",
             INR => "印度盧比", SAR => "阿幣", KWD => "科威特幣", NOK => "挪威幣",
             SWF => "瑞士法郎", SEK => "瑞典克朗", DMK => "丹麥克朗", BRC => "巴西幣",
             MEP => "墨西哥披索", ARS => "阿根廷披索", CLP => "智利披索",
             VEB => "委瑞內拉幣", ZAR => "南非幣", RUR => "俄羅斯盧布",
             NZD => "紐西蘭元" );

my %coin = (
    USD => "1", TWD => "2", JPY => "3", HKD => "4", MCY => "5",
    GBP => "6", EUR => "7", CAD => "8", AUD => "9", THB => "10",
    SGD => "11", KOW => "12", IDR => "13", MYR => "14", PHP => "15",
    INR => "16", SAR => "17", KWD => "18", NOK => "19", SWF => "20",
    SEK => "21", DMK => "22", BRC => "23", MEP => "24", ARS => "25",
    CLP => "26", VEB => "27", ZAR => "28", RUR => "29", NZD => "30"
   );

my %calias = ( GRP => 'GBP', "RMB" => "MCY", "YEN" => "JPY", "CHF" =>"SWF", "NTD" => "TWD");

sub can_answer { 1 }

sub answer {
    my ($s) = @args;
    my $reply;
    my $allsymbol = join("|",keys %coin) . "|" . join("|",keys %calias);
    my $qmark = '(?:[\s\?]|？)*';

    my $confidence = 1;
    if ( $s =~ /^([\d\.\+\-\*\/]+)\s*($allsymbol)\s+to\s+($allsymbol)$qmark$/i ) {
        $reply = $self->get_ex_money($1,$2,$3);
    } elsif ( $s =~ /^([\d\.\+\-\*\/]+)\s*($allsymbol)$qmark$/i ) {
        $reply = $self->get_ex_money($1,$2);
    } elsif ( $s =~ /^currency\s+list([\s\?])*?/i ) {
        $reply = "You may ask my to exchange these currency: "
            . join(",", map { $cname{$_}."($_)" } sort keys %cname );
    } elsif ($s =~ m{help (currency|money|exchang)} ) {
        $reply =
            qq{I can do currency exchanging, Example: 10 USD to NTD?, or simply "10 USD". To list all currency, say "currency list" to me};
    }
    else {
        return { content => "",  confidence => 0 };
    }

    return {
        content    => $reply,
        confidence => $confidence
    };
}

sub get_ex_money {
    my ($money,$from,$to) = @args;
    $to ||= "TWD"; # Default to TWD
    $from = $self->expand_alias(uc($from));
    $to   = $self->expand_alias(uc($to));

    while($from eq $to) {$to = (shuffle(keys %coin))[0];}
    my $ua = LWP::UserAgent->new(timeout => 300) or die $!;;
    my $res;

    my $reply;
    try {
        $SIG{ALRM} = sub { die "alarm\n"; };
	alarm(30);
        my $url ="http://tw.money.yahoo.com/currency_exc_result?amt=${money}&from=${from}&to=${to}";
        $res = $ua->get($url);
	alarm(0);

        if ($res->is_success) {
            my $dom = Mojo::DOM->new;
            $dom->parse(Encode::decode_utf8($res->content));

            my $data = $dom->find('.exponent')->[0]->all_text;

            if ($data =~ /經過計算後，\s*([\d\.]+\s*\w+ = [\d\.]+\s*\w+)\s/) {
                $reply = $1;
            }

            # $reply = $data;
        }
    } catch {
        say "ERROR: $_";
    };

    return $reply;
}

sub expand_alias {
    my ($from) = @args;
    if(defined $calias{$from}) {
	$from = $calias{$from};
    }
    return $from;
}

1;
