#!/usr/bin/perl -w

use strict;

use JSON;
use FindBin;

use lib "$FindBin::Bin/lib";
use commands::parser;
use sites::parser;
use utils::db;

my $dbh = utils::db::get_session;
$sites::parser::dbh = $dbh;

foreach (<>) {
    my $content = decode_json $_;
    foreach (keys %{$content}) {
	    my $id = sites::parser::parse(undef, $content->{'author'}, ['@NightIIEs.facebook'], $content->{'link'});
        commands::parser::tag($content->{'msg'}, ['@NightIIEs.facebook']);
    }
}
