package Jabbot::FrontEnd::Console;
use Jabbot::FrontEnd -Base;

my $alarm_timer = 3;

sub on_alarm {
    print "1\n";
    alarm $alarm_timer;
}

sub process {
    local $SIG{ALRM} = \&on_alarm;
    my $hub = $self->hub;
    alarm($alarm_timer);
    $| = 1;
    print "jabbot> ";
    while(<>){
        $hub->pre_process;
        my $reply = $hub->process($_);
        print $reply->text," \n" if(defined $reply->text);
        $hub->post_process;
        print "jabbot> ";
    }
}
