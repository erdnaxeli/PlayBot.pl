package commands::get;

use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

use lib "$FindBin::Bin/lib/";
use utils::print;

our $dbh;
our $irc;
our $log;

sub exec {
	my ($kernel, $nick, $chan, $msg) = @_;

    # if we are in a query or arg -all, we search in all the channels
    my $all = 0;
    $all = 1 if ($chan->[0] !~ /^#/ || $msg =~ s/-a(ll)?//);

    my @tags = ($msg =~ /#([a-zA-Z0-9_-]+)/g);
    my $content;
    my $req;
    my $sth;
    my $rows;

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
        $sth = $dbh->prepare('select id, sender, title, url, duration
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
            $req = 'select id, sender, title, url, duration
                from playbot
                natural join playbot_tags
                where tag in ('.$params.')';
            $req .= ' and '.$words_sql if ($words_sql);
            $req .= ' group by id
                having count(*) >= ?
                order by rand()';

            $sth = $dbh->prepare($req);
            $sth->execute(@tags, @words_param, scalar @tags);
        }
        else {
            $req = 'select p.id, p.sender, p.title, p.url, duration
                from playbot p
                natural join playbot_tags pt
                join playbot_chan pc on p.id = pc.content
                where pt.tag in ('.$params.')';
            $req .= ' and '.$words_sql if ($words_sql);
            $req .= ' and pc.chan = ?
                group by p.id
                having count(*) >= ?
                order by rand()';

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
            $req = 'select id, sender, title, url, duration from playbot';
            $req .= ' where '.$words_sql if ($words_sql);
            $req .= ' group by id';
            $req .= ' order by rand()';

            $sth = $dbh->prepare($req);
            $sth->execute (@words_param);
        }
        else {
            $req = 'select p.id, p.sender, p.title, p.url, duration
                from playbot p
                join playbot_chan pc on p.id = pc.content
                where pc.chan = ?';
            $req .= ' and '.$words_sql if ($words_sql);
            $req .= ' group by p.id';
            $req .= ' order by rand()';

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

    # this is specific to the mysql driver
    $rows = $sth->rows;
    
    $sth = $dbh->prepare("select tag
        from playbot_tags
        where id = ?
    ");
    $sth->execute($content->[0]);

    my @tags;
    while (my $data = $sth->fetch) {
        my $tag = $data->[0];
        $tag =~ s/([a-zA-Z0-9_-]+)/#$1/;
        push @tags, $tag;
    }

    my %content_h;
    $content_h{'id'} = $content->[0];
    $content_h{'author'} = $content->[1];
    $content_h{'title'} = $content->[2];
    $content_h{'url'} = $content->[3];
    $content_h{'duration'} = $content->[4];
    $content_h{'tags'} = \@tags;

    my $msg = utils::print::print(\%content_h);
    $msg .= ' [' . $rows . ' résultat';
    $msg .= 's' if ($rows > 1);
    $msg .= ']';
    $irc->yield(privmsg => $chan => $msg);

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
