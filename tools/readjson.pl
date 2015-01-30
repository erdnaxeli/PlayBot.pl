#!/usr/bin/perl -w

use strict;

use JSON;
use FindBin;

use lib "$FindBin::Bin/lib";
use commands::parser;
use sites::parser;
use utils::db;
use utils::Logging;

my $dbh = utils::db::get_session;
my $log = Logging->new('STDOUT', 1);
$sites::parser::dbh = $dbh;
$sites::parser::log = $log;

foreach (<>) {
    my $content = decode_json $_;
    foreach (keys %{$content}) {
	    my $id = sites::parser::parse(undef, $content->{'author'}, ['#nightiies.facebook'], $content->{'link'});
        commands::parser::tag($content->{'msg'}, ['#nightiies.facebook']);
    }
}
