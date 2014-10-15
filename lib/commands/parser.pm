package commands::parser;

use strict;
use Try::Tiny;

use lib "$FindBin::Bin/lib/";
use commands::fav;
use commands::later;
use commands::tag;
use commands::get;
use utils::id;

my $lastID;
my $irc;
my $dbh;

sub setConf {
    my ($ircNew, $dbhNew, $log, $lastIDnew) = @_;

    $commands::fav::dbh = $dbhNew;
    $commands::tag::dbh = $dbhNew;
    $commands::get::dbh = $dbhNew;
    $commands::later::dbh = $dbhNew;
    $utils::id::dbh = $dbhNew;

    $commands::fav::log = $log;
    $commands::tag::log = $log;
    $commands::get::log = $log;
    $commands::later::log = $log;
    $utils::id::log = $log;

    $commands::fav::irc = $ircNew;
    $commands::get::irc = $ircNew;

    $lastID = $lastIDnew;
    $irc = $ircNew;
    $dbh = $dbhNew;
}

sub exec {
	my ($kernel, $user, $chan, $msg) = @_;
	my ($nick, $mask) = split(/!/,$user);

    if ($msg =~ /^ *!fav(?: ([0-9]+))?/) {
        my $id = ($1) ? $1 : $lastID->{$chan->[0]};

        commands::fav::exec($nick, $id)
	}
	elsif ($msg =~ /^ *!later(?: (-?[0-9]+))?(?: in ([0-9]*)?(h|m|s)?)?/) {
        my $id = $1;
        my $offset = ($1) ? $1 : 0;
        my ($time, $unit) = ($2, $3);

        if ($id eq '' || $id =~ /^-/) {
            my $sth = $dbh->prepare('
                SELECT content
                FROM playbot_chan
                WHERE chan = ?
                AND date <= NOW()
                ORDER BY date DESC
                LIMIT 1');
            $sth->execute($chan->[0]);
            $id = $sth->fetch->[0];
        }

        commands::later::exec($kernel, $nick, $id, $offset, $chan, $time, $unit);
	}
    elsif ($msg =~ /^( *!tag)(?:( +)([0-9]+))?/) {
        my $id = $3;

        if ($id) {
            $msg = substr $msg, (length $1) + (length $2) + (length $id);
        }
        else {
            $id = $lastID->{$chan->[0]};
            $msg = substr $msg, (length $1) + (length $2);
        }

        commands::tag::exec($id, $msg);
    }
    elsif ($msg =~ /^( *!get)(?: +.*)?$/) {
        $msg = substr $msg, (length $1) + 1;
        my @args = ($kernel, $nick, $chan, $msg);
        my $id = commands::get::exec(@args);

        if ($id) {
            $lastID->{$chan->[0]} = $id;
        }
    }
    elsif ($msg =~ /^ *!help/) {
		$irc->yield(privmsg => $nick => '!fav [<id>] : enregistre la vidéo dans les favoris');
		$irc->yield(privmsg => $nick => '!tag [<id>] <tag1> <tag2> ... : tag la vidéo');
		$irc->yield(privmsg => $nick => '!later [<id>] [in <x>[s|m|h]] : vidéo rappelée par query (par défaut temps de 6h)');
		$irc->yield(privmsg => $nick => "    Sans id précisée, la dernière vidéo postée sur le chan est utilisée.");
		$irc->yield(privmsg => $nick => '    L\'id peut être négatif, auquel cas -1 correspond à l\'avant dernière vidéo.');
		$irc->yield(privmsg => $nick => '!get [<id>|<query>] : sort aléatoirement une vidéo');
		$irc->yield(privmsg => $nick => '    Si un id est précisé, sort ce contenu (s\'il existe).');
		$irc->yield(privmsg => $nick => '    <query> : composée de tags commençant par un \'#\' ou de mots. Les mots sont recherché dans le titre ainsi que le nom de l\'auteur du contenu.');
		$irc->yield(privmsg => $nick => "Un tag est de la forme « #[a-zA-Z0-9_]+ ». Par exemple « #loLILol_mdr42 » est un tag valide, tandis que « #céducaca » et « #je-suis-nul » n'en sont pas et seront considéré respectivement comme « #c » et « #je ».");
        $irc->yield(privmsg => $nick => "Toutes les commandes fonctionnent en query.");
        $irc->yield(privmsg => $nick => 'Niveau vie privée, potentiellement toute commande (excepté !help) entraine un enregistrement dans la base de données avec au minimum la date et l\'heure et le nick de la personne ayant exécuté la commande.');
    }
    else {
        return 0;
    }

    return 1;
}

sub tag {
    my ($msg, $chan) = @_;
    my @tags = ($msg =~ /#([a-zA-Z0-9_-]+)/g);

    commands::tag::exec($lastID->{$chan->[0]}, "@tags");
}

1;
