package commands::parser;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(exec irc);

use lib "$FindBin::Bin/lib/commands/";
#use fav;
#use later;
#use tag;
#use help;

our $irc;
our $dbh;

sub exec {
	my ($kernel, $user, $chan, $msg) = @_;
	my ($nick,$mask) = split(/!/,$user);

    if ($msg =~ /^!fav( ([0-9]+))?/) {
		my $id = ($2) ? $2 : $lastID;

		my $sth = $dbh->prepare_cached('SELECT user FROM playbot_codes WHERE nick = ?');
		$sth->execute($nick)
			or $log->error("Couldn't finish transaction: " . $dbh->errstr);

		if (!$sth->rows) {
			$irc->yield(privmsg => $nick => "Ce nick n'est associé à aucun login arise. Va sur http://nightiies.iiens.net/links/fav pour obtenir ton code personel.");
		}
        else {
    		my $sth2 = $dbh->prepare_cached('INSERT INTO playbot_fav (id, user) VALUES (?, ?)');
		    $sth2->execute($id, $sth->fetch->[0])
	    		or $log->error("Couldn't finish transaction: " . $dbh->errstr);
        }
	}
	elsif ($msg =~ /^!later(?: ([0-9]+))?(?: in ([0-9]*)?(h|m|s)?)?/) {
		my ($id, $time, $unit) = ($1, $2, $3);

		$id = $lastID if (!$id);
		$time = 6 if (!$time);
		$time *= ($unit eq 's') ? 1 : ($unit eq 'm') ? 60 : 3600;
		$kernel->delay_set('_later', $time, $nick, $id);
	}
    elsif ($msg =~ /^!tag( +([0-9]+))?/) {
        my $id = ($2) ? $2 : $lastID;
        while ($msg =~ /#([a-zA-Z0-9_-]+)/g) {
            addTag($id, $1);
        }
    }
    elsif ($msg =~ /^!help/) {
		$irc->yield(privmsg => $chan => '!fav [<id>] : enregistre la vidéo dans les favoris');
		$irc->yield(privmsg => $chan => '!tag [<id>] <tag1> <tag2> ... : tag la vidéo');
		$irc->yield(privmsg => $chan => '!later [<id>] [in <x>[s|m|h]] : vidéo rappelée par query (par défaut temps de 6h)');
		$irc->yield(privmsg => $chan => 'Sans id précisée, la dernière vidéo postée est utilisée.');
    }
}

1;
