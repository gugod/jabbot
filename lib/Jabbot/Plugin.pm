package Jabbot::Plugin;
use Spoon::Plugin -Base;
our $VERSION = '0.01';

stub 'class_id';
const config_file => '';
const class_title_prefix => 'Jabbot';

sub new {
    return $self if ref $self;
    super;
}

sub init {
    $self->use_class('config');
    $self->use_class('message');
    $self->config->add_file($self->config_file);
}

sub reply {
    my ($text,$priority) = @_;
    $self->message->new(text => $text,
                        priority => (defined $text)?$priority:0);
}

sub trim {
    foreach(@_) {
        s/^\s+//;
        s/\s+$//;
    }
}
