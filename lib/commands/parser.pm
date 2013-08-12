package commands::parser;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(exec);

use strict;

use lib "$FindBin::Bin/lib/";
use commands::fav;
use commands::later;
use commands::tag;
use commands::get;

our %lastID;

my $irc;

sub setConf {
    my ($ircNew, $dbh, $log) = @_;

    $commands::fav::dbh = $dbh;
    $commands::tag::dbh = $dbh;
    $commands::get::dbh = $dbh;

    $commands::fav::log = $log;
    $commands::tag::log = $log;

    $commands::fav::irc = $ircNew;
    $commands::get::irc = $ircNew;

    $irc = $ircNew;
}

sub exec {
    my @args = @_;
	my ($kernel, $user, $chan, $msg) = @args;
	my ($nick,$mask) = split(/!/,$user);

    if ($msg =~ /^!fav(?: ([0-9]+))?/) {
        my $id = ($1) ? $1 : $lastID{$chan->[0]};

        commands::fav::exec($nick, $id)
	}
	elsif ($msg =~ /^!later(?: ([0-9]+))?(?: in ([0-9]*)?(h|m|s)?)?/) {
        my $id = ($1) ? $1 : $lastID{$chan->[0]};
        my ($time, $unit) = ($2, $3);

        commands::later::exec($kernel, $nick, $id, $time, $unit);
	}
    elsif ($msg =~ /^!tag(?: +([0-9]+))?/) {
        my $id = $1;

        if ($id) {
            $msg = substr $msg, 4 + length $id + 1;
        }
        else {
            $id = $lastID{$chan->[0]};
            $msg = substr $msg, 4;
        }

        commands::tag::exec($id, $msg);
    }
    elsif ($msg =~ /^!get/) {
        my $id = commands::get::exec(@args);

        if ($id) {
            $lastID{$chan->[0]} = $id;
        }
    }
    elsif ($msg =~ /^!help/) {
		$irc->yield(privmsg => $nick => '!fav [<id>] : enregistre la vidéo dans les favoris');
		$irc->yield(privmsg => $nick => '!tag [<id>] <tag1> <tag2> ... : tag la vidéo');
		$irc->yield(privmsg => $nick => '!later [<id>] [in <x>[s|m|h]] : vidéo rappelée par query (par défaut temps de 6h)');
		$irc->yield(privmsg => $nick => '!get [<tags>] : sort aléatoirement une vidéo');
		$irc->yield(privmsg => $nick => "Sans id précisée, la dernière vidéo postée sur le chan est utilisée (ça marche aussi avec !get).");
		$irc->yield(privmsg => $nick => "Un tag est de la forme « #[a-zA-Z0-9_-]+ ». Par exemple « #loLILol-mdr_lol42 » est un tag valide, tandis que « #céducaca » n'en ai pas un (seul « #c » sera considéré).");
    }
    else {
        return 0;
    }

    return 1;
}

sub tag {
    my ($msg, $chan) = @_;

    commands::tag::exec($lastID{$chan->[0]}, $msg);
}

1;
