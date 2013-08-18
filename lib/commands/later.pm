package commands::later;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(exec);

our $dbh;
our $log;

sub exec {
    my ($kernel, $nick, $id, $time, $unit) = @_;

	$time = 6 if (!$time);
	$time *= ($unit eq 's') ? 1 : ($unit eq 'm') ? 60 : 3600;
	$kernel->delay_set('_later', $time, $nick, $id);

    my $sth = $dbh->prepare_cached('INSERT INTO playbot_later (content, nick, date) VALUES (?, ?, ?)');
	unless (defined $sth) {
        $log->error("Couldn't prepare querie; aborting");
        return;
    }

	$sth->execute($id, $nick, time + $time)
        or $log->error("Couldn't finish transaction: " . $dbh->errstr);
}

1;
