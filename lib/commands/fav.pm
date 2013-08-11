package commands::fav;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(exec);

our $dbh;

sub exec {
    my ($nick, $id) = @_;

    my $sth = $dbh->prepare_cached('SELECT user FROM playbot_codes WHERE nick = ?');
    $sth->execute($nick)
	    or $log->error("Couldn't finish transaction: " . $dbh->errstr);

    if (!$sth->rows) {
	    $irc->yield(privmsg => $nick => "Ce nick n'est associé à aucun login arise. Va sur http://nightiies.iiens.net/links/fav pour obtenir ton code personel.");
    }
    else {
        my $sth2 = $dbh->prepare_cached('INSERT INTO playbot_fav (id, user) VALUES (?, ?)');
	    $sth2->execute($id, $sth->fetch->[0])
	        or $log->error("Couldn't finish transaction: " . $dbh->errstr);
    }
}

1;
