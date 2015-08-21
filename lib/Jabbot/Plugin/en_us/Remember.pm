package Jabbot::Plugin::en_us::Remember;
use v5.18;
use Object::Tiny qw(core);

sub can_answer {
}

sub answer {
}

1;

__END__

=begin NOTES

Syntax:
    "remember,"  + SPACES + TEXT
    "recall,"    + SPACES + TEXT

Examples:

    jabbot: remember, The force will be with you.
    jabbot: remember, diaspora is a decentralized SNS system.
    jabbot: remember, git is a decentralized version control system

    jabbot: recall, The force
    jabbot> The force will be with you

    jabbot: recall, decentralized system
    jabbot> diaspora is a decentralized SNS system.
    jabbot> git is a decentralized version control system.

=cut
