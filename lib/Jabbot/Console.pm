package Jabbot::Console;
use Jabbot::Base -Base;
use Term::ReadLine;

sub process {
    my $term = new Term::ReadLine 'Jabbot-Console';
    while(defined($_ = $term->readline('jabbot> '))){
        my $reply = $self->hub->process($_);
        print $term->OUT "$reply \n";
    }
}
