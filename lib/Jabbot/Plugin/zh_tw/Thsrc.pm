package Jabbot::Plugin::zh_tw::Thsrc;
use common::sense;
use utf8;
use HTML::TreeBuilder::Select;
use WWW::Mechanize;

sub new { bless {}, shift }

sub can_answer {
    my ($self, $text) = @_;

    if ($text =~ m/高鐵\s*[,:]?\s*(..)\s*到\s*(..)\s*/) {
        $self->{matched} = [$1, $2];
        return 1;
    }
    return 0;
}

sub answer {
    my ($self, undef) = @_;
    my $content = $self->thsrc_query(@{ $self->{matched} });
    return {
        content    => $content,
        confidence => 1
    }
}

my @stations = qw{台北 板橋 桃園 新竹 台中 嘉義 台南 左營};
my $i = 1;
my %station_id = map { $_, $i++ } @stations;

sub thsrc_query {
    my $self = shift;
    my ($from, $to) = map { $station_id{$_} } @_;
    my ($h,$mday,$mon,$year) = (localtime(time))[2,3,4,5];
    $mon += 1;
    $year += 1900;
    $h = "0$h" if $h < 10;

    my $html = $self->fetch_thsrc_query_result($from, $to, "$year/$mon/$mday","$h:00");
    my @schedule = $self->parse_thsrc_query_result($html);

    return "查無高鐵車次" unless @schedule;

    return join " | ", map {
        my ($car, $sale, $from_time, $to_time) = @$_;

        $sale = $sale ? ((100 - $sale) . "折") : "原價";

        $_ = "$car 車次 ($sale) $from_time ~ $to_time";
    } @schedule;
}

sub fetch_thsrc_query_result {
    my ($self, $from, $to, $date, $time) = @_;
    die 'from should be 1..7'  unless $from =~ /^[1234567]$/;
    die 'to   should be 1..7'  unless $to   =~ /^[1234567]$/;
    die 'time should be hh:mm' unless $time =~ /^\d\d:\d\d$/;
    die 'date should be yyyy/mm/dd'  unless $date   =~ /^\d\d\d\d\/\d\d?\/\d\d?$/;

    my $ua = WWW::Mechanize->new;
    $ua->get('http://www.thsrc.com.tw/tc/ticket/tic_time_search.asp');

    $ua->submit_form(
        form_name => "frm1",
        fields => {
            from       => $from,
            to         => $to,
            sDate      => $date,
            TimeTable  => $time,
            FromOrDest => "From"
        }
    );
    return $ua->content;
}

sub parse_thsrc_query_result {
    my $self = shift;
    my $html = shift;
    my @result = ();
    my @row = ();

    my $tree = HTML::TreeBuilder::Select->new_from_content($html);
    my @cells = $tree->select("table.tic_normal_title2 td");

    for my $index (0..$#cells) {
        if ($index % 4 == 1) {
            my $html = $cells[$index]->as_HTML;

            if ($html =~ /orange/) {
                # 35% off
                push @row, 35;
            }
            elsif ($html =~ /blue/) {
                # 15% off
                push @row, 15;
            }
            else {
                # 0% off
                push @row, 0;
            }
        }
        else {
            my $text = $cells[$index]->as_trimmed_text;
            push @row, $text;
        }

        if ($index % 4 == 3) {
            push @result, [@row];
            @row = ();
        }
    }

    return @result;
}


1;
