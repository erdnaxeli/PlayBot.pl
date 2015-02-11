package commands::tag;

our $dbh;
our $log;

sub exec {
    my ($id, $msg) = @_;

    while ($msg =~ /#?([a-zA-Z0-9_]+)/g) {
        addTag($id, $1);
    }
}

sub addTag
{
    my ($id, $tag) = @_;

    my $sth;

    $sth = $dbh->prepare('INSERT INTO playbot_tags (id, tag) VALUES (?, ?)');
    $log->error("Couldn't prepare querie; aborting") unless (defined $sth);

    eval {
        $sth->execute($id, $tag)
    };
	if ($@) {
        $log->error("Couldn't finish transaction: " . $@);
    }
}

1;
