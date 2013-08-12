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
            group by id
            having count(*) >= ?');
        $sth->execute(@tags, scalar @tags);

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
                select floor( count(*) * rand() ) as randomValue
                from playbot
                )
            as v on playbot.id = v.randomValue
            limit 1');
        $sth->execute;
        $content = $sth->fetch;
        
        if (!$content) {
            $irc->yield(privmsg => $chan => "Je n'ai rien dans ce registre.");
            return
        }
    }
    
    if ($content->[1]) {
    	$irc->yield(privmsg => $chan => '['.$content->[0].'] '.$content->[2].' | '.$content->[1].' => '.$content->[3]) ;
    }
    else {
    	$irc->yield(privmsg => $chan => '['.$content->[0].'] '.$content->[2].' => '.$content->[3]) ;
    }
}

1;
