use inc::Module::Install;

name('Jabbot');
abstract('Jabberish bot that talks too much');
author('Kang-min Liu <gugod@gugod.org>');
version_from('lib/Jabbot/Base.pm');
license('perl');

requires(
         Kwiki => '0.37',
         Spoon => '0,23',
         Net::IRC => 0,
         Chatbot::Eliza => 0,
         Date::Day => 0,
         POE => 0,
         POE::Component::IRC => 0,
         POE::Component::IKC => 0,
         POE::Component::RSSAggregator => 0,
         Perl6::Say => 0,
         WWW::Shorten::0rz => 0,
         OurNet::Chatbot => 0,
         Time::Interval => 0,
         Net::OSCAR => 0,
         Net::Jabber => 0,
         Perl6::Say => 0,
        );

check_nmake();
auto_install();

&WriteAll();
