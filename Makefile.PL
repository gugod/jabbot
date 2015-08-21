use inc::Module::Install;

name('Jabbot');
abstract('Jabberish bot that talks too much');
author('Kang-min Liu <gugod@gugod.org>');
version_from('lib/Jabbot.pm');
license('mit');
cpanfile();

&WriteAll();
