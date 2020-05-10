use v5.18;
use strict;

package Jabbot::Types {
    use Type::Library -base;
    use Type::Utils -all;
    use Types::Standard -all;

    declare "JabbotIdentifier", as Str, where { defined($_) and $_ ne '' and lc($_) eq $_ };
    declare "JabbotNodeIdentifier",    as "JabbotIdentifier";
    declare "JabbotNetworkIdentifier", as "JabbotIdentifier";
    declare "JabbotAuthorIdentifier",  as "JabbotIdentifier";
    declare "JabbotChannelIdentifier", as "JabbotIdentifier";

    declare "JabbotMessage", as Dict[
        author  => JabbotAuthorIdentifier(),
        channel => JabbotChannelIdentifier(),
        network => JabbotNetworkIdentifier(),
        body    => Str
    ];

    declare "JabbotQA", as Dict[
        question => JabbotMessage(),
        answer   => JabbotMessage()
    ];

    __PACKAGE__->meta->make_immutable;
};

1;
