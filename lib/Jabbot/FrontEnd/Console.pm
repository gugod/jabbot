package Jabbot::Console;
use Spoon 0.21 -Base;
use Term::ReadLine;

const config_class => 'Kwiki::Config';

sub process {
    my $hub = $self->load_hub(@_);
    my $term = new Term::ReadLine 'Jabbot::Console';
    my $OUT = $term->OUT;
    while(defined($_ = $term->readline('jabbot> '))){
        $hub->pre_process;
        my $reply = $hub->process($_);
        print $OUT $reply->text," \n" if(defined $reply->text);
        $hub->post_process;
    }
}
