package commands::later;

our $dbh;
our $log;

sub exec {
    my ($kernel, $nick, $id, $offset, $chan, $time, $unit) = @_;

	$time = 6 if (!$time);
	$time *= ($unit eq 's') ? 1 : ($unit eq 'm') ? 60 : 3600;

    while ($offset < 0) {
        my $sth = $dbh->prepare_cached('
            SELECT content
            FROM playbot_chan
            WHERE date < (SELECT date
                        FROM playbot_chan
                        WHERE content = ?
                        AND chan = ?
                        ORDER BY date DESC
                        LIMIT 1)
            AND chan = (SELECT chan
                        FROM playbot_chan
                        WHERE content = ?
                        AND chan = ?
                        ORDER BY date DESC
                        LIMIT 1)
            ORDER BY date DESC
            LIMIT 1');
	    unless (defined $sth) {
            $log->error("Couldn't prepare querie; aborting");
            return;
        }	
        $sth->execute($id, $chan->[0], $id, $chan->[0])
            or $log->error("Couldn't finish transaction: " . $dbh->errstr);

        my $content = $sth->fetch;
        return unless ($content);
        $id = $content->[0];
        $offset++;
    }

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
