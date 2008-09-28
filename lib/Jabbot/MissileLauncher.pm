package Jabbot::MissileLauncher;
use Jabbot::Plugin -Base;

const class_id => 'missilelauncher';

sub process {
    my $msg = shift;

    if ($msg->text =~ /^(up|down|left|right|fire|[lfrdu]+)$/i) {
        my $cmd = $1;
        system("perl ~/tmp/m.pl $cmd");
        return;
    }
    
    print STDERR "missile command proccessed... or not\n";
}

1;

