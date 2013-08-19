package commands::get;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(exec);

use strict;
use warnings;

our $dbh;
our $irc;

sub exec {
	my ($kernel, $user, $chan, $msg) = @_;

    my @tags = ($msg =~ /#?([a-zA-Z0-9_-]+)/g);
    my $content;

    # if we are in a query, we search in all the channels
    my $all = ($chan->[0] !~ /^#/) ? 1 : 0;

    if (@tags) {
        my $params = join ', ' => ('?') x @tags;
        my $sth;

        if ($all) {
            $sth = $dbh->prepare('select id, sender, title, url
                from playbot
                natural join playbot_tags
                where tag in ('.$params.')
                group by id
                having count(*) >= ?
                order by rand()
                limit 1');
            $sth->execute(@tags, scalar @tags);
        }
        else {
            $sth = $dbh->prepare('select p.id, p.sender, p.title, p.url
                from playbot p
                natural join playbot_tags pt
                join playbot_chan pc on p.id = pc.content
                where pt.tag in ('.$params.')
                and pc.chan = ?
                group by p.id
                having count(*) >= ?
                order by rand()
                limit 1');
            $sth->execute(@tags, $chan->[0], scalar @tags);
        }

        $content = $sth->fetch;

        if (!@{$content}) {
            $irc->yield(privmsg => $chan => "Je n'ai rien dans ce registre.");
            return
        }
    }
    else {
        my $sth;

        if ($all) {
            $sth = $dbh->prepare('select id, sender, title, url from playbot
                order by rand()
                limit 1');
            $sth->execute;
        }
        else {
            $sth = $dbh->prepare('select p.id, p.sender, p.title, p.url
                from playbot p
                join playbot_chan pc on p.id = pc.content
                where pc.chan = ?
                order by rand()
                limit 1');
            $sth->execute($chan->[0]);
        }

        $content = $sth->fetch;
        
        if (!$content) {
            $irc->yield(privmsg => $chan => "Poste d'abord du contenu, n00b.");
            return
        }
    }
    
    my $sth = $dbh->prepare("select group_concat(tag separator ' ')
        from playbot_tags
        where id = ? and context = 0
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

    return $content->[0];
}

1;
