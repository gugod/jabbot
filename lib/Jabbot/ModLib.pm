
package Jabbot::ModLib;

use Jabbot::Lib;
# Preprocessing

our %MSG;
local $/ = undef;
my $txt = <>;

%MSG = txt2msg($txt);

1;
