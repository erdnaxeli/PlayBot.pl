package commands::later;

our $dbh;
our $log;

sub exec {
    my ($kernel, $nick, $id, $chan, $time, $unit) = @_;

	$time = 6 if (!$time);
	$time *= ($unit eq 's') ? 1 : ($unit eq 'm') ? 60 : 3600;

    my $sth = $dbh->prepare_cached('INSERT INTO playbot_later (content, nick, date) VALUES (?, ?, ?)');
	unless (defined $sth) {
        $log->error("Couldn't prepare querie; aborting");
        return;
    }	
	$sth->execute($id, $nick, time + $time)
        or $log->error("Couldn't finish transaction: " . $dbh->errstr);
    
    $kernel->delay_set('_later', $time, $nick, $id);
}

1;
