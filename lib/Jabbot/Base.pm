package Jabbot::Base;
use Spoon::Base -Base;
our $VERSION = '3.00_01';

use Perl6::Say;

our @EXPORT = qw(say);

field config => -init => '$self->hub->config';

