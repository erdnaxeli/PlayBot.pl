package sites::parser;

use lib "$FindBin::Bin/lib/sites/";
use youtube;
use soundcloud;
use mixcloud;
use zippy;
use dailymotion;

use lib "$FindBin::Bin/lib/";
use utils::db;
use utils::print;
use commands::parser;

our $irc;
our $log;

sub parse {
	my ($kernel, $user, $chan, $msg) = @_;
	my ($nick,$mask) = split(/!/,$user);

    my %content;
    my $id;
    my $dbh = utils::db::main_session();

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
    elsif ($msg =~ m#(?:^|[^!])https?://www.dailymotion.com/video/([a-z0-9]+)#) {
        eval { %content = dailymotion::get($1) };

        $content{'site'} = 'dailymotion';
        $content{'url'} = 'https://www.dailymotion.com/video/' . $1;
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
            eval {
                my $sth = $dbh->prepare('
                    INSERT INTO playbot (type, url, sender, title, duration)
                    VALUES (?,?,?,?,?)');
		        $log->error("Couldn't prepare querie; aborting") unless (defined $sth);

		        $sth->execute($content{'site'}, $content{'url'},
                    $content{'author'}, $content{'title'}, $content{'duration'});

                $dbh->commit;
            };
            if ($@) {
			    $log->error("Couldn't finish transaction: " . $@);
            }
	    }

	    # sélection de l'id de la vidéo insérée
        $id = $sth->{mysql_insertid};
	    if (!$id) {
            # la vido avait déjà été insérée
            # L'état de la bdd est stable (puisqu'on a en fait rien fait),
            # on peut commiter.
            $dbh->commit;

		    my $sth = $dbh->prepare('SELECT id FROM playbot WHERE url = ?');
		    $log->error("Couldn't prepare querie; aborting") unless (defined $sth);

		    $sth->execute($content{'url'})
			    or $log->error("Couldn't finish transaction: " . $dbh->errstr);

		    $id = $sth->fetch->[0];
	    }

        # insertion du chan
        my $sth = $dbh->prepare('
            INSERT INTO playbot_chan (content, chan, sender_irc)
            VALUES (?,?,?)');
		$log->error("Couldn't prepare querie; aborting") unless (defined $sth);

        $sth->execute($id, $chan->[0], $nick)
            or $log->error("Couldn't finish transaction: " . $dbh->errstr);

        # in all cases, we commit now
        $dbh->commit;

        commands::parser::tag($msg, $chan);

        my @tags;
        # get tags
        $sth = $dbh->prepare("select tag
            from playbot_tags
            where id = ?
            ");
        $sth->execute($id);

        while (my $data = $sth->fetch) {
            my $tag = $data->[0];
            $tag =~ s/([a-zA-Z0-9_-]+)/#$1/;
            push @tags, $tag;
        }
        $dbh->commit;

        # message sur irc
        $content{'id'} = $id;
        $content{'tags'} = \@tags;
        delete $content{'url'};
		$irc->yield(privmsg => $chan => utils::print::print(\%content));
    }

    return $id;
}

1;
