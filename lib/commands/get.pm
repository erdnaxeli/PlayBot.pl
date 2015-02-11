package commands::get;

use strict;
use warnings;

use lib "$FindBin::Bin/lib/";
use utils::print;
use utils::db;
use utils::db::query;

use commands::get::query;

our $irc;
our $log;

sub exec {
	my ($kernel, $nick, $chan, $msg) = @_;

    my $query = commands::get::query->new(
        chan => $chan->[0],
        query  => ($msg) ? $msg : ''
    );

    my $db_query = utils::db::query->new();
    my $content = $db_query->get($query);
    my $rows = $db_query->get_rows($query);

    if (!$content) {
        if ($rows > 0) {
            # the request was already executed, there is nothing more
            $irc->yield(privmsg => $chan => "Tu tournes en rond, Jack !");
        }
        elsif (@{$query->words} or @{$query->tags}) {
            $msg = "Je n'ai rien dans ce registre.";

            if (not $query->is_global) {
                # we check is there is result with global
                my $q = commands::get::query->new(
                    chan => $query->chan,
                    query  => $query->query . ' -a'
                );

                my $rows = $db_query->get_rows($q);
                if ($rows > 0) {
                    $msg .= ' ' . $rows . ' résultat';
                    $msg .= 's' if ($rows > 1);
                    $msg .= ' trouvé';
                    $msg .= 's' if ($rows > 1);
                    $msg .= ' avec une recherche globale.';
                }

            }

            $irc->yield(privmsg => $chan => $msg);
        }
        else {
            $irc->yield(privmsg => $chan => "Poste d'abord du contenu, n00b.");
        }

        return
    }

    my $dbh = utils::db::main_session();
    my $sth = $dbh->prepare("select tag
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

    my $irc_msg = utils::print::print(\%content_h);
    $irc_msg .= ' [' . $rows . ' résultat';
    $irc_msg .= 's' if ($rows > 1);
    $irc_msg .= ']';
    $irc->yield(privmsg => $chan => $irc_msg);

    # we save the get like a post
    $sth = $dbh->prepare_cached('
        INSERT INTO playbot_chan (content, chan, sender_irc)
        VALUES (?,?,?)');
    $log->error("Couldn't prepare querie; aborting") unless (defined $sth);

    $sth->execute($content->[0], $chan->[0], "PlayBot")
        or $log->error("Couldn't finish transaction: " . $dbh->errstr);

    $dbh->commit();

    return $content->[0];
}


1;
