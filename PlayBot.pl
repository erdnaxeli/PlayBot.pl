#!/usr/bin/perl -w
use strict;
use warnings;

use POE;
use FindBin;

use lib "$FindBin::Bin/lib/";
use sessions::irc;

# Boucle des events
POE::Kernel->run();
exit 0;
