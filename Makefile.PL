use inc::Module::Install;

name('Jabbot');
abstract('Jabberish bot that talks too much');
author('Kang-min Liu <gugod@gugod.org>');
version_from('lib/Jabbot/Base.pm');
license('perl');

requires(
    Kwiki => '0.37',
    Net::IRC => 0,
    Chatbot::Eliza => 0,
    Date::Day => 0,
    POE => 0,
    POE::Component::IRC => 0,
    POE::Component::IKC => 0,
    POE::Component::RSSAggregator => 0,
);

check_nmake();
auto_install();

&WriteAll();
