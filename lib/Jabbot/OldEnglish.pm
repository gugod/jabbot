package Jabbot::OldEnglish;
use Jabbot::Plugin -Base;

const class_id => 'OldEnglish';

sub process {
    my $text = shift->text;
    
    if ($text =~ /\bthou\b/) {
        $self->reply('thou speakst also ye olde English?');
    }
}

