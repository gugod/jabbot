package Jabbot::FrontEnd::Console;
use Jabbot::FrontEnd -Base;
use Term::ReadLine;
use Encode;
use YAML;
sub process {
    my $hub = $self->hub;
    my $term = new Term::ReadLine 'Jabbot::Console';
    my $OUT = $term->OUT;
    binmode($OUT,':utf8');
    while(defined($_ = $term->readline('jabbot> '))){
        $hub->pre_process;
        my $reply = $hub->process(
            $self->hub->message->new(
                text => Encode::decode_utf8($_),
                from => $ENV{USER},
                channel => 'console',
               ));
        print $OUT "=> ",$reply->text,"\n";
        $hub->post_process;
    }
}
