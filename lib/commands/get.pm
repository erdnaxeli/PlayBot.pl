package commands::get;

use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

our $dbh;
our $irc;
our $log;

sub exec {
	my ($kernel, $nick, $chan, $msg) = @_;

    # if we are in a query or arg -all, we search in all the channels
    my $all = 0;
    $all = 1 if ($chan->[0] !~ /^#/ || $msg =~ s/-all//);

    my @tags = ($msg =~ /#([a-zA-Z0-9_-]+)/g);
    my $content;
    my $req;
    my $sth;

    my @words = ($msg =~ /(?:^| )([a-zA-Z0-9_-]+)/g);
    my @words_param;
    while ($msg =~ /(?:^| )([a-zA-Z0-9_-]+)/g) {
        unshift @words_param, '%'.$1.'%';
    }

    my $words_sql;
    foreach (@words) {
        $words_sql .= ' and ' if ($words_sql);
        $words_sql .= "concat(sender, ' ', title) like ?";
    }

    if (@words && looks_like_number($words[0])) {
        $sth = $dbh->prepare('select id, sender, title, url
            from playbot
            where id = ?');
        $sth->execute($words[0]);

        $content = $sth->fetch;

        if (!$content) {
            $irc->yield(privmsg => $chan => "Je n'ai rien dans ce registre.");
            return
        }
    }
    elsif (@tags) {
        my $params = join ', ' => ('?') x @tags;

        if ($all) {
            $req = 'select id, sender, title, url
                from playbot
                natural join playbot_tags
                where tag in ('.$params.')';
            $req .= ' and '.$words_sql if ($words_sql);
            $req .= ' group by id
                having count(*) >= ?
                order by rand()
                limit 1';

            $sth = $dbh->prepare($req);
            $sth->execute(@tags, @words_param, scalar @tags);
        }
        else {
            $req = 'select p.id, p.sender, p.title, p.url
                from playbot p
                natural join playbot_tags pt
                join playbot_chan pc on p.id = pc.content
                where pt.tag in ('.$params.')';
            $req .= ' and '.$words_sql if ($words_sql);
            $req .= ' and pc.chan = ?
                group by p.id
                having count(*) >= ?
                order by rand()
                limit 1';

            $sth = $dbh->prepare($req);
            $sth->execute(@tags, @words_param, $chan->[0], scalar @tags);
        }

        $content = $sth->fetch;

        if (!$content) {
            $irc->yield(privmsg => $chan => "Je n'ai rien dans ce registre.");
            return
        }
    }
    else {
        if ($all) {
            $req = 'select id, sender, title, url from playbot';
            $req .= ' where '.$words_sql if ($words_sql);
            $req .= ' order by rand() limit 1';

            $sth = $dbh->prepare($req);
            $sth->execute (@words_param);
        }
        else {
            $req = 'select p.id, p.sender, p.title, p.url
                from playbot p
                join playbot_chan pc on p.id = pc.content
                where pc.chan = ?';
            $req .= ' and '.$words_sql if ($words_sql);
            $req .= ' order by rand()
                limit 1';

            $sth = $dbh->prepare($req);
            $sth->execute($chan->[0], @words_param);
        }

        $content = $sth->fetch;
        
        if (!$content) {
            if (@words) {
                $irc->yield(privmsg => $chan => "Je n'ai rien dans ce registre.");
            }
            else {
                $irc->yield(privmsg => $chan => "Poste d'abord du contenu, n00b.");
            }
            return
        }
    }
    
    $sth = $dbh->prepare("select group_concat(tag separator ' ')
        from playbot_tags
        where id = ?
        group by id");
    $sth->execute($content->[0]);

    my $tags = $sth->fetch;

    if ($tags) {
        $tags = $tags->[0];
        $tags =~ s/([a-zA-Z0-9_-]+)/#$1/g;
    }
    else {
        $tags = "";
    }

    if ($content->[1]) {
    	$irc->yield(privmsg => $chan => '['.$content->[0].'] '.$content->[2].' | '.$content->[1].' => '.$content->[3].' '.$tags) ;
    }
    else {
    	$irc->yield(privmsg => $chan => '['.$content->[0].'] '.$content->[2].' => '.$content->[3].' '.$tags) ;
    }

    # we save the get like a post
    my $sth2 = $dbh->prepare_cached('
        INSERT INTO playbot_chan (content, chan, sender_irc)
        VALUES (?,?,?)');
    $log->error("Couldn't prepare querie; aborting") unless (defined $sth2);

    $sth2->execute($content->[0], $chan->[0], "PlayBot")
        or $log->error("Couldn't finish transaction: " . $dbh->errstr);

    return $content->[0];
}

1;
