package Jabbot::Plugin;
use Spoon::Plugin -Base;

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
    my ($text,$must) = @_;
    $self->message->new(text => $text, must_say => (defined $text)?$must:undef);
}

sub trim {
    foreach(@_) {
        s/^\s+//;
        s/\s+$//;
    }
}
