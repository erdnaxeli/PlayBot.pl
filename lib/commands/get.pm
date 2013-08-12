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

    my @tags = ($msg =~ /#([a-zA-Z0-9_-]+)/g);
    my $content;

    if (@tags) {
        my $params = join ', ' => ('?') x @tags;
        my $sth = $dbh->prepare('select id, sender, title, url from playbot
            natural join playbot_tags
            where tag in ('.$params.')
            and chan = ?
            group by id
            having count(*) >= ?');
        $sth->execute(@tags, $chan->[0], scalar @tags);

        $content = $sth->fetchall_arrayref;

        if (!@{$content}) {
            $irc->yield(privmsg => $chan => "Je n'ai rien dans ce registre.");
            return
        }
        else {
            $content = $content->[rand @{$content}];
        }
    }
    else {
        my $sth = $dbh->prepare('select id, sender, title, url from playbot
            join (
                select floor ((max(id) - min(id)) * rand()) + min(id) as randomValue
                from playbot
                )
            as v on playbot.id >= v.randomValue
            where chan = ?
            limit 1');
        $sth->execute($chan->[0]);
        $content = $sth->fetch;
        
        if (!$content) {
            $irc->yield(privmsg => $chan => "Poste d'abord du contenu, n00b.");
            return
        }
    }
    
    if ($content->[1]) {
    	$irc->yield(privmsg => $chan => '['.$content->[0].'] '.$content->[2].' | '.$content->[1].' => '.$content->[3]) ;
    }
    else {
    	$irc->yield(privmsg => $chan => '['.$content->[0].'] '.$content->[2].' => '.$content->[3]) ;
    }

    return $content->[0];
}

1;
