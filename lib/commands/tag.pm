package commands::tag;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(exec);

our $dbh;
our $log;

sub exec {
    my ($id, $msg) = @_;

    while ($msg =~ /#?([a-zA-Z0-9_-]+)/g) {
        addTag($id, $1);
    }
}

sub addTag
{
    my ($id, $tag) = @_;

    my $sth = $dbh->prepare_cached('INSERT INTO playbot_tags (id, tag) VALUES (?, ?)');
	$log->error("Couldn't prepare querie; aborting") unless (defined $sth);

	$sth->execute($id, $tag)
		or $log->error("Couldn't finish transaction: " . $dbh->errstr);
}

1;
