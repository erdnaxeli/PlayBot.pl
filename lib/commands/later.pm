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

    if ($id == -1) {
        my $sth = $dbh->prepare_cached('
            SELECT content
            FROM playbot_chan
            WHERE id < (SELECT id
                        FROM playbot_chan
                        WHERE content = ?)
            AND chan = (SELECT chan
                        FROM playbot_chan
                        WHERE content = ?)
            ORDER BY id DESC
            LIMIT 1');
	    unless (defined $sth) {
            $log->error("Couldn't prepare querie; aborting");
            return;
        }	
        $sth->execute($id, $id)
            or $log->error("Couldn't finish transaction: " . $dbh->errstr);

        return unless ($content);
        my $content = $sth->fetch;
        $id = $content->[0];
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
