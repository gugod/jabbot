package Jabbot::zh_tw::Thsrc;
use Jabbot::Plugin -Base;
use utf8;
use HTML::TreeBuilder::Select;
use WWW::Mechanize;

const class_id => 'zhtw_thsrc';

my @stations = qw{台北 板橋 桃園 新竹 台中 嘉義 台南 左營};
my $i = 1;
my %station_id = map { $_, $i++ } @stations;

sub process {
    my $msg = shift;
    my $s = $msg->text;

    if ($s =~ /高鐵\s*[,:]?\s*(..)\s*到\s*(..)\s*/) {
        my ($from, $to);
        $from = $station_id{$1};
        $to   = $station_id{$2};
        my @result = $self->thsrc_query($from, $to);

        my $r = "";
        for(@result) {
            my ($car, $sale, $from_time, $to_time) = @$_;
            $sale = $sale ? ((100 - $sale) . "折") : "沒打折";
            $r .= "$car 車次, $sale, $from_time - $to_time. ";
        }
        $self->reply($r, 1);
    }
}

sub thsrc_query {
    my ($from, $to) = @_;
    my $h = (localtime(time))[2];
    my $html = $self->fetch_thsrc_query_result($from, $to, "$h:00");
    return $self->parse_thsrc_query_result($html);
}

sub fetch_thsrc_query_result {
    my ($from, $to, $time) = @_;
    die 'from should be 1..7'  unless $from =~ /^[01234567]$/;
    die 'to   should be 1..7'  unless $to   =~ /^[01234567]$/;
    die 'time should be hh:mm' unless $time =~ /^\d\d:\d\d$/;

    my $ua = WWW::Mechanize->new;
    $ua->get('http://www.thsrc.com.tw/tc/ticket/tic_time_search.asp');
    $ua->submit_form(
        form_name => "frmticket1",
        fields => {
            from       => $from,
            to         => $to,
            TimeTable  => $time,
            FromOrDest => "From"
        }
    );
    return $ua->content;
}

sub parse_thsrc_query_result {
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
