package Jabbot::Plugin;
use Spoon::Plugin -Base;

stub 'class_id';
const config_file => '';
const class_title_prefix => 'Jabbot';

field config  => -init => '$self->hub->config';
field message => -init => '$self->hub->message';

sub new {
    return $self if ref $self;
    super;
}

sub init {
    $self->hub->config->add_file($self->config_file);
}

sub reply {
    my ($text,$must) = @_;
    $self->message->new(text => $text, must_say => (defined $text)?$must:undef);
}

sub trim {
    for(@_) {
        s/^\s+//;
        s/\s+$//;
    }
}

sub rand_choose {
    $_[int(rand($#_+1))];
}
