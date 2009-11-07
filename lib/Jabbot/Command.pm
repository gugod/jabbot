package Jabbot::Command;
use Spoon::Command -Base;
use UNIVERSAL::require;

sub usage {
    warn <<END;
usage:
    jabbot -new [path]
    jabbot -update [path]

    jabbot -run FrontEnd::IRC
    jabbot -run BackEnd::FeedAggregator
END
}

sub create_registry {
    my $hub = Jabbot->new->load_hub('config.yaml', -plugins => 'plugins');
    my $registry = $hub->registry;
    my $registry_path = $registry->registry_path;
    $self->msg("Generating Jabbot Registry '$registry_path'\n");
    $registry->update;
    if ($registry->validate) {
        $registry->write;
    }
}

sub handle_update {
    chdir io->dir(shift || '.')->assert->open . '';
    die "Can't update non Jabbot directory!\n" unless -d 'plugin';
    $self->create_registry;
    $self->hub->registry->load;
}

sub handle_new {
    $self->assert_directory(shift, 'Kwiki');
    $self->add_new_default_config;
    $self->install('config');
    $self->create_registry;
    $self->hub->registry->load;
    io('plugin')->mkdir;
    $self->set_permissions;
}

sub handle_run {
    my $name = shift;
    my $class = "Jabbot::${name}";
    $class->require or die "Failed to load front-end ${name}\nError: $@";
    my $type = ($name =~ /Front/ ? 'frontend' : 'backend');
    $self->hub->config->{"${type}_class"} = $class;
    $self->hub->$type->process(@_);
}

sub add_new_default_config {
    $self->hub->config->add_config(
        {
            irc_class => 'Jabbot::IRC',
            console_class => 'Jabbot::Console',
            command_class => 'Jabbot::Command',
            config_class => 'Jabbot::Config',
            hooks_class => 'Spoon::Hooks',
            hub_class => 'Jabbot::Hub',
            registry_class => 'Jabbot::Registry',
        }
    );
}

sub assert_directory {
    chdir io->dir(shift || '.')->assert->open->name;
    my $noun = shift;
    die "Can't make new $noun in a non-empty directory\n"
      unless io('.')->empty;
}
