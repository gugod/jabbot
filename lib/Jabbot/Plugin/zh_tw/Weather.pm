package Jabbot::Plugin::zh_tw::Weather;
use Jabbot::Plugin;

sub can_answer {
    my ($text) = @args;

    ($self->{area}) = $text =~ m/((?:南投|嘉義|基隆|宜蘭|屏東|彰化|新北|新竹|桃園|澎湖|臺中|臺北|臺南|臺東|台中|台北|台南|台東|花蓮|苗栗|連江|金門|雲林|高雄)(?:縣|市)?)/;
    ($self->{hint}) = $text =~ m/(冷|熱|雨|晴|天氣(?:預報)?)/;

    return $self->{area} && $self->{hint};
}

sub answer {
    my ($text) = @args;

}


1;
