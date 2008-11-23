#!/usr/bin/env perl
# -*- cperl -*-

use strict;
use warnings;
use File::Path;
use File::Spec;

my $JABBOT_HOME;

BEGIN {
    $JABBOT_HOME = $ENV{JABBOT_HOME};
    if (defined($ENV{SCRIPT_FILENAME}) && !defined($ENV{JABBOT_HOME})) {
        my $home = $ENV{SCRIPT_FILENAME};
        my ($volume,$directories,$file) = File::Spec->splitpath( $home );
        my @dirs = File::Spec->splitdir($directories);
        @dirs[-1,-2,-3,-4] = ();
        ${JABBOT_HOME} = File::Spec->catdir(@dirs);
    }
}

unless (${JABBOT_HOME}) {
    print "Content-Type: text/html\n\n";
    print "<p>Please define JABBOT_HOME environment variable.</p>\n";
    print "<dl>";
    while ( my ($k,$v) = each %ENV) {
        print "<dt>$k</dt><dd>$v</dd>";
    }
    print "</dl>";
    exit;
}

use lib "${JABBOT_HOME}/lib";

use Cwd;
Cwd::chdir(${JABBOT_HOME});

use Jabbot;
my @configs = qw(config.yaml -plugins plugins);
my $j = Jabbot->new;
$j->load_hub(@configs);
$j->hub->config->{frontend_class} = 'Jabbot::FrontEnd::CGI';
$j->hub->frontend->process;
