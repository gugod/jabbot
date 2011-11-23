use inc::Module::Install;

name('Jabbot');
abstract('Jabberish bot that talks too much');
author('Kang-min Liu <gugod@gugod.org>');
version_from('lib/Jabbot/Base.pm');
license('perl');

include     'Module::AutoInstall';
requires(
         Spoon => '0,23',
         Date::Day => 0,
         POE => 0,
         POE::Component::IRC => 6.06,
         POE::Component::IKC => 0,
         Time::Interval => 0,
         Time::HiRes => 0,
         Perl6::Say => 0,
         URI::Title => 0,
         Regexp::Common => 0,
         'WWW::Shorten' => 0,
#         Net::OSCAR => 0,
);

feature 'JA Romanize' =>
        -default => 0,
        Lingua::JA::Romanize::Japanese => 0
        ;

feature 'Eliza Chatbot' =>
        -default => 0,
        Chatbot::Eliza => 0,
        ;

feature 'Jabber supports' =>
        -default => 0,
        'Net::Jabber' => 0
        ;

feature 'Feed Aggregator Backend' => 
        -default => 0,
        'POE::Component::RSSAggregator' => 0,
        'POE::Component::AtomAggregator' => 0
         'WWW::Shorten::isgd' => 0,
        ;

feature 'CPANAuthor Plugin' =>
        -default    => 0,
        'Acme::CPANAuthors'   => 0,
        'Cache' => 0,
        ;

feature 'GitHub' =>
        -default => 0,
        'POE::Component::Server::HTTP' => 0,
        'POE::Component::IKC::ClientLite' => 0,
        'CGI::Simple' => 0,
        'HTTP::Status' => 0,
        'JSON::XS' => 0,
        'WWW::Shorten::0rz' => 0,
        ;


check_nmake();
auto_install();

&WriteAll();
