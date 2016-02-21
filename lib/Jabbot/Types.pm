use v5.18;
use strict;

package Jabbot::Types {
    use Type::Library -base;
    use Type::Utils -all;
    use Types::Standard -all;

    declare "JabbotIdentifier", as Str, where { lc($_) eq $_ };
    declare "JabbotNodeIdentifier",    as "JabbotIdentifier";
    declare "JabbotNetworkIdentifier", as "JabbotIdentifier";

    declare "JabbotMessageAuthor", as Dict[
        network => JabbotNetworkIdentifier(),
        id      => Str
    ];
    
    declare "JabbotMessage", as Dict[
        author => JabbotMessageAuthor(),
        body   => Str
    ];

    declare "JabbotQA", as Dict[
        question => JabbotMessage(),
        answer   => JabbotMessage()
    ];

    __PACKAGE__->meta->make_immutable;
};

1;
