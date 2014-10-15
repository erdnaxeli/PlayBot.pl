package utils::id;

use strict;
use Scalar::Util qw(looks_like_number);

# Used to get a proper id from an index.
# The public subroutine is get($chan, $index).
# args :
#   - $chan : the chan initiating the request. It cannot be empty and must
#       start with '#' except if it is a query.
#   - $index : the index.
#       - an id (ex: 5089)
#       - an offset (ex: -3 to have the third track before the last one).
#           0 means the last track.
#       - empty, wich means the last one.

# The object used to communicate with the database and the loging object.
# MUST BE SET before using any subrouting.
our $dbh; 
our $log;

# The public method.
sub get {
    my ($chan, $index) = @_;
    my $id;

    if (!defined($index) or !length($index)) {
        $id = _get_last_id ($chan);
    } elsif (!looks_like_number($index)) {
        die "wrong index";
    } elsif ($index < 0) {
        $id = _get_from_offset ($index, $chan);
    } elsif (_test_if_exists ($index, $chan)) {
        $id = $index;
    } else {
        die "wrong index";
    }

    return $id;
}

sub _get_from_offset {
    my ($offset, $chan) = @_;
    my $id = _get_last_id ($chan);

    while ($offset < 0) {
        my $sth = $dbh->prepare('
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
        $sth->execute($id, $chan, $id, $chan)
            or $log->error("Couldn't finish transaction: " . $dbh->errstr);

        my $content = $sth->fetch;
        return unless ($content);
        $id = $content->[0];
        $offset++;
    }

    return $id;
}

sub _test_if_exists {
    my ($index, $chan) = @_;

    my $sth = $dbh->prepare('
        SELECT content
        FROM playbot_chan
        WHERE content = ?
        AND chan = ?
        LIMIT 1
    ');

    $sth->execute($index, $chan)
        or $log->error("Couldn't finish transaction: " . $dbh->errstr);

    my $content = $sth->fetch;
    if ($content) {
        return 1;
    }
    else {
        return 0;
    }
}

sub _get_last_id {
    my ($chan) = @_;

    my $sth = $dbh->prepare('
        SELECT content
        FROM playbot_chan
        WHERE chan = ?
        AND date <= NOW()
        ORDER BY date DESC
        LIMIT 1');
    $sth->execute($chan);
    return $sth->fetch->[0];
}

1;
