package Jabbot::FrontEnd::Console;
use Jabbot::FrontEnd -Base;
use Term::ReadLine;

my $term;

sub on_alarm {
    my $OUT = $term->OUT || \*STDOUT;
    print $OUT "1\n";
    alarm 10;
}

sub process {
    local $SIG{ALRM} = \&on_alarm;
    my $hub = $self->hub;
    $term = new Term::ReadLine(__PACKAGE__);
    my $OUT = $term->OUT || \*STDOUT;
    alarm(10);
    while(defined($_ = $term->readline('jabbot> '))){
        $hub->pre_process;
        my $reply = $hub->process($_);
        print $OUT $reply->text," \n" if(defined $reply->text);
        $hub->post_process;
    }
}
