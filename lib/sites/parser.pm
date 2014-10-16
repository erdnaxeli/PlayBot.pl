package sites::parser;

use lib "$FindBin::Bin/lib/sites/";
use youtube;
use soundcloud;
use mixcloud;
use zippy;

use lib "$FindBin::Bin/lib/";
use commands::parser;
use commands::tag;
use utils::print;

our $irc;
our $dbh;
our $log;

sub parse {
	my ($kernel, $user, $chan, $msg) = @_;
	my ($nick,$mask) = split(/!/,$user);

    my %content;
    my $id;

    # parsing
    if ($msg =~ m#(?:^|[^!])https?://(?:www.youtube.com/watch\?[a-zA-Z0-9_=&-]*v=|youtu.be/)([a-zA-Z0-9_-]+)#) {
		eval { %content = youtube::get($1) };

		$content{'site'} = 'youtube';
        $content{'url'} = 'https://www.youtube.com/watch?v='.$1;
	}
	elsif ($msg =~ m#(^|[^!])https?://soundcloud.com/([a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+)#) {
		my $url = 'https://www.soundcloud.com/'.$2;
		eval { %content = soundcloud::get($url) };
		$content{'site'} = 'soundcloud';
	}
	elsif ($msg =~ m#(^|[^!])https?://www.mixcloud.com/([a-zA-Z0-9-_]+/[a-zA-Z0-9-_]+)#) {
		my $url = 'https://www.mixcloud.com/'.$2;
		eval { %content = mixcloud::get($url) };
		$content{'site'} = 'mixcloud';
	}
	elsif ($msg =~ m#((^|[^!])http://www[0-9]+.zippyshare.com/v/[0-9]+/file.html)#) {
		my $url = $1;
		eval { %content = zippy::get($url) };
		$content{'site'} = 'zippyshare';
	}

    # something goes wrong ?
    if ($@) {
        $log->warning ($@);
        return;
    }

    # if we get a new content, we must save it
    if (%content) {
	    if ($debug) {
		    $log->debug($content{'url'});
	    }
	    else {
		    # insertion de la vidéo dans la bdd
		    my $sth = $dbh->prepare_cached('
                INSERT INTO playbot (type, url, sender, title)
                VALUES (?,?,?,?)');
		    $log->error("Couldn't prepare querie; aborting") unless (defined $sth);

		    $sth->execute($content{'site'}, $content{'url'}, $content{'author'}, $content{'title'})
			    or $log->error("Couldn't finish transaction: " . $dbh->errstr);
	    }

	    # sélection de l'id de la vidéo insérée
        $id = $sth->{mysql_insertid};
	    if (!$id) {
		    my $sth = $dbh->prepare_cached('SELECT id FROM playbot WHERE url = ?');
		    $log->error("Couldn't prepare querie; aborting") unless (defined $sth);

		    $sth->execute($content{'url'})
			    or $log->error("Couldn't finish transaction: " . $dbh->errstr);

		    $id = $sth->fetch->[0];
	    }

	    # message sur irc
        $content{'id'} = $id,
		$irc->yield(privmsg => $chan => utils::print::print(\%content));

        # insertion du chan
        my $sth = $dbh->prepare_cached('
            INSERT INTO playbot_chan (content, chan, sender_irc)
            VALUES (?,?,?)');
		$log->error("Couldn't prepare querie; aborting") unless (defined $sth);

        $sth->execute($id, $chan->[0], $nick)
            or $log->error("Couldn't finish transaction: " . $dbh->errstr);
    }

    return $id;
}

1;
