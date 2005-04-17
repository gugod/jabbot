package Jabbot::Hub;
use Spoon::Hub -Base;
use List::Util qw(shuffle);
use UNIVERSAL qw(isa can);

sub init {
    $self->use_class('messages');
    $self->use_class('message');
}

sub process {
    $self->preload;
    my $msg = shift;
    my @replies = grep {
        defined $_->text && $_->text ne '' && !($_->text =~ /^\s+$/)
    } grep {
        defined $_ && isa($_,'Jabbot::Message')
    } map {
        my $reply;
        eval {$reply = $self->$_->process($msg);};
        $@ ? $self->message->new : $reply;
    } $self->all_plugin_ids;
    if(my @musts = grep {$_->must_say} @replies) {
        $self->messages->append($_) for @musts;
    } else {
        $self->messages->append((shuffle @replies)[0] || $self->message->new);
    }
    $self->messages->next;
}

sub all_plugin_ids {
    map {$_->{id}} @{$self->registry->lookup->plugins};
}
