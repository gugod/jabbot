package Jabbot::FrontEnd::Console;
use Jabbot::FrontEnd -Base;
use Term::ReadLine;

sub process {
    my $hub = $self->hub;
    my $term = new Term::ReadLine 'Jabbot::Console';
    my $OUT = $term->OUT;
    while(defined($_ = $term->readline('jabbot> '))){
        $hub->pre_process;
        my $reply = $hub->process($_);
        print $OUT $reply->text," \n" if(defined $reply->text);
        $hub->post_process;
    }
}
