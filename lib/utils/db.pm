package utils::db;

use strict;
use warnings;

use DBI;
use JSON;
use FindBin;

my $conf;
my $dbh;

BEGIN {
    chdir "$FindBin::Bin/";
    local $/;
    open CONF, '<', 'playbot.conf';
    my $json = <CONF>;
    $conf = decode_json($json);
}

sub main_session {
    $dbh = get_new_session() if (not $dbh or not $dbh->ping);
    return $dbh;
}

sub get_new_session {
    my $dbh = DBI->connect('DBI:mysql:'.$conf->{'bdd'}.';host='.$conf->{'host'}, $conf->{'user'}, $conf->{'passwd'}, {
            PrintError => 1,
	        AutoCommit => 0
    	})
    	or die("Couldn't connect to database: ".DBI->errstr);

    $dbh->do(qq{SET NAMES 'utf8';});
    return $dbh;
}

1;
