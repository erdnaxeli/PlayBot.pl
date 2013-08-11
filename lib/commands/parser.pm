package commands::parser;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(exec);

use lib "$FindBin::Bin/lib/";
use commands::fav;
use commands::later;
use commands::tag;

our %lastID;

my $irc;

sub setConf {
    my ($ircNew, $dbh, $log) = @_;

    $commands::fav::dbh = $dbh;
    $commands::tag::dbh = $dbh;

    $commands::fav::log = $log;
    $commands::tag::log = $log;

    $irc = $ircNew;
}

sub exec {
	my ($kernel, $user, $chan, $msg) = @_;
	my ($nick,$mask) = split(/!/,$user);

    if ($msg =~ /^!fav(?: ([0-9]+))?/) {
        $id = ($1) ? $1 : $lastID{$chan->[0]};

        commands::fav::exec($nick, $id)
	}
	elsif ($msg =~ /^!later(?: ([0-9]+))?(?: in ([0-9]*)?(h|m|s)?)?/) {
        my $id = ($1) ? $1 : $lastID{$chan->[0]};
        my ($time, $unit) = ($2, $3);

        commands::later::exec($kernel, $nick, $id, $time, $unit);
	}
    elsif ($msg =~ /^!tag(?: +([0-9]+))?/) {
        my $id = ($1) ? $1 : $lastID{$chan->[0]};

        commands::tag::exec($id, $msg);
    }
    elsif ($msg =~ /^!help/) {
		$irc->yield(privmsg => $nick => '!fav [<id>] : enregistre la vidéo dans les favoris');
		$irc->yield(privmsg => $nick => '!tag [<id>] <tag1> <tag2> ... : tag la vidéo');
		$irc->yield(privmsg => $nick => '!later [<id>] [in <x>[s|m|h]] : vidéo rappelée par query (par défaut temps de 6h)');
		$irc->yield(privmsg => $nick => 'Sans id précisée, la dernière vidéo postée sur le chan est utilisée.');
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
