package commands::get;

use strict;
use warnings;

use lib "$FindBin::Bin/lib/";
use utils::print;
use utils::db;

use commands::get::query;

our $irc;
our $log;

my $last_req;
my $dbh;
my $sth;

sub exec {
	my ($kernel, $nick, $chan, $msg) = @_;

    my $query = commands::get::query->new(
        chan => $chan->[0],
        query  => ($msg) ? $msg : ''
    );

    my $content;
    my $req;
    my $rows;

    if (not defined $last_req or not ($query ~~ $last_req)) {
        # we close a previous session if needed
        if ($dbh) {
            $sth->finish if $sth->{'Active'};
            $dbh->commit;
            $dbh->disconnect;
        }

        $dbh = utils::db::get_new_session;

        my @words_param;
        foreach (@{$query->words}) {
            unshift @words_param, '%'.$_.'%';
        }

        my $words_sql;
        foreach (@{$query->words}) {
            $words_sql .= ' and ' if ($words_sql);
            $words_sql .= "concat(sender, ' ', title) like ?";
        }

        if ($query->id >= 0) {
            $sth = $dbh->prepare('select id, sender, title, url, duration
                from playbot
                where id = ?');
            $sth->execute($query->id);
        }
        elsif (@{$query->tags}) {
            my @where;

            foreach my $tag (@{$query->tags}) {
                unshift @where, 'p.id in (select pt.id from playbot_tags pt where pt.tag = ?)';
            }

            my $where = join ' and ' => @where;

            if ($query->is_global) {
                $req = 'select id, sender, title, url, duration
                    from playbot
                    where '.$where;
                $req .= ' and '.$words_sql if ($words_sql);
                $req .= ' group by id
                    order by rand()';

                $sth = $dbh->prepare($req);
                $sth->execute(@{$query->tags}, @words_param);
            }
            else {
                $req = 'select p.id, p.sender, p.title, p.url, duration
                    from playbot p
                    join playbot_chan pc on p.id = pc.content
                    where '.$where;
                $req .= ' and '.$words_sql if ($words_sql);
                $req .= ' and pc.chan = ?
                    group by p.id
                    order by rand()';

                $sth = $dbh->prepare($req);
                $sth->execute(@{$query->tags}, @words_param, $query->chan);
            }
        }
        else {
            if ($query->is_global) {
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
                $sth->execute($query->chan, @words_param);
            }
        }
    }

    $content = $sth->fetch;

    if (!$content) {
        if ($last_req ~~ $query) {
            # the request was already executed, there is nothing more
            $irc->yield(privmsg => $chan => "Tu tournes en rond, Jack !");
        }
        elsif (@{$query->words} or @{$query->tags}) {
            $irc->yield(privmsg => $chan => "Je n'ai rien dans ce registre.");
        }
        else {
            $irc->yield(privmsg => $chan => "Poste d'abord du contenu, n00b.");
        }

        $last_req = undef;
        return
    }

    # this is specific to the mysql driver
    $rows = $sth->rows;
    
    my $sth2 = utils::db::main_session()->prepare("select tag
        from playbot_tags
        where id = ?
    ");
    $sth2->execute($content->[0]);

    my @tags;
    while (my $data = $sth2->fetch) {
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

    my $irc_msg = utils::print::print(\%content_h);
    $irc_msg .= ' [' . $rows . ' résultat';
    $irc_msg .= 's' if ($rows > 1);
    $irc_msg .= ']';
    $irc->yield(privmsg => $chan => $irc_msg);

    # we save the get like a post
    $sth2 = utils::db::main_session()->prepare_cached('
        INSERT INTO playbot_chan (content, chan, sender_irc)
        VALUES (?,?,?)');
    $log->error("Couldn't prepare querie; aborting") unless (defined $sth2);

    $sth2->execute($content->[0], $chan->[0], "PlayBot")
        or $log->error("Couldn't finish transaction: " . $dbh->errstr);

    # we save the request
    $last_req = $query;

    return $content->[0];
}


1;
