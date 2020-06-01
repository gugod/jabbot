package Jabbot::Plugin::en_us::CurrencyConvert;
use v5.18;
use utf8;
use Object::Tiny qw(core);

use Importer 'Finance::Currency::Convert::SCSB' => (
    convert_currency => { -prefix => 'scsb_' }
);
use Importer 'Finance::Currency::Convert::Esunbank' => (
    convert_currency => { -prefix => 'esunbank_' }
);

use Memoize;

my $RE_CURRENCY = qr/USD|JPY|HKD|EUR|GBP|CHF|SEK|AUD|CAD|SGD|DKK|THB|NZD|ZAR|CNY|KRW|TWD/x;

my @func = (\&scsb_convert_currency, \&esunbank_convert_currency);

sub exchange_rate {
    my ($from_currency, $to_currency) = @_;
    state $i = 0;
    my $conv = sub {
        my @args = @_;
        my ($error, $res);
        for (0..3) {
            ($error, $res) = $func[$i]->(@args);
            $i = 1 - $i;
            sleep(3) if $error;
            last unless $error;
        }
        return ($error, $res);
    };

    my $rate = ($from_currency eq 'TWD') ? 1 : $conv->(1, $from_currency, 'TWD');

    if ($to_currency ne 'TWD') {
        my $rate2 = $conv->(1, $to_currency, 'TWD');
        $rate = $rate / $rate2;
    }

    return $rate;
}
memoize('exchange_rate');

sub convert_currency {
    my ($amount, $from_currency, $to_currency) = @_;
    return $amount * exchange_rate($from_currency, $to_currency);
}

sub can_answer {
    my ($self, $message) = @_;

    if ($message->{body} =~ /\A \s* (?<amount>[0-9]+(\.[0-9]+)?+) \s+ (?<from_currency>$RE_CURRENCY) \s+ to \s+ (?<to_currency>$RE_CURRENCY) \s* \z/x ) {
        $self->{matched} = {
            amount => $+{amount},
            from_currency => $+{from_currency},
            to_currency => $+{to_currency},
        };
        return 1;
    }
    return 0;
}

sub answer {
    my ($self, $message) = @_;

    my ($amount, $from_currency, $to_currency) = @{$self->{matched}}{'amount', 'from_currency', 'to_currency'};
    my $ans = convert_currency($amount, $from_currency, $to_currency);

    return {
        body => sprintf('%s %s is %.2f %s', $amount, $from_currency, $ans, $to_currency),
        score => 1,
    }
}

1;
