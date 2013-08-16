package commands::tag;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(exec);

use Lingua::StopWords qw(getStopWords);

our $dbh;
our $log;

sub exec {
    my ($id, $msg) = @_;

    while ($msg =~ /#?([a-zA-Z0-9_-]+)/g) {
        addTag($id, $1);
    }
}

sub addContext
{
    my ($id, $msg) = @_;

    while ($msg =~ /#?([a-zA-Z0-9_-]+)/g) {
        addTag($id, $1, 1);
    }
}

sub addTag
{
    my ($id, $tag, $context) = @_;
    my $stopwords_en = getStopWords('en');
    my $stopwords_fr = getStopWords('fr');

    return if ($stopwords_en->{lc $tag} or $stopwords_fr->{lc $tag});

    my $sth = $dbh->prepare_cached('INSERT INTO playbot_tags (id, tag, context) VALUES (?, ?, ?)');
	$log->error("Couldn't prepare querie; aborting") unless (defined $sth);

	$sth->execute($id, $tag, ($context) ? 1 : 0)
		or $log->error("Couldn't finish transaction: " . $dbh->errstr);
}

1;
