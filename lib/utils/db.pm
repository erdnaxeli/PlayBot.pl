package utils::db;

use strict;
use warnings;

use DBI;
use JSON;
use FindBin;

my $conf;


BEGIN {
    chdir "$FindBin::Bin/";
    local $/;
    open CONF, '<', 'playbot.conf';
    my $json = <CONF>;
    $conf = decode_json($json);
}


sub get_session {
    my $dbh = DBI->connect('DBI:mysql:'.$conf->{'bdd'}.';host='.$conf->{'host'}, $conf->{'user'}, $conf->{'passwd'}, {
    	    PrintError => 0,
	        AutoCommit => 1,
    		mysql_auto_reconnect => 1
    	})
    	or die("Couldn't connect to database: ".DBI->errstr);

    return $dbh;
}

1;
