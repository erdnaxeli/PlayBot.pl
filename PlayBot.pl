#!/usr/bin/perl -w
use strict;
use warnings;
use POE;
use POE::Component::IRC;
use POSIX 'strftime';
use DBI;
use Tie::File;
use JSON;

use Logging;
use youtube;
use soundcloud;
use mixcloud;
use zippy;


# nom du fichier
my $bot = $0;

my $log = Logging->new('STDOUT', 1);

# config
my $serveur = 'IRC.iiens.net';
my $nick = 'PlayBot';
my $port = 6667;
my $ircname = 'nightiies';
my $username = 'nightiies';
my @channels = qw(#nightiies #dansiie #pimpim #vitamine #fanfare #groop);
my $admin = 'moise';
my $baseurl = 'http://nightiies.iiens.net/links/';
my @nicksToVerify;
my @codesToVerify;
my $lastID;

my $debug = 0;

# mode debug
if ($#ARGV + 1) {
	@channels = qw(#hormone);
	$nick = 'kikoo';
	$debug = 1;
}


local $/;
open CONF, '<', 'playbot.conf';
my $json = <CONF>;
my $conf = decode_json($json);


## CONNEXION 
my ($irc) = POE::Component::IRC->spawn();
my $dbh = DBI->connect('DBI:mysql:'.$conf->{'bdd'}.';host='.$conf->{'host'}, $conf->{'user'}, $conf->{'passwd'}, {
	        PrintError => 0,
	        AutoCommit => 1,
		mysql_auto_reconnect => 1
	  })
	or die("Couldn't connect to database: ".DBI->errstr);


# Evenements que le bot va gérer
POE::Session->create(
	inline_states => {
		_start     => \&bot_start,
		irc_001    => \&on_connect,
		irc_public => \&on_speak,
		irc_msg    => \&on_query,
		irc_notice => \&on_notice,
		_flux	   => \&flux,
		_later     => \&later
	},
);


my %commandes_admin = ("cycle" => \&cycle);



### FONCTIONS
sub flux
{
	my $kernel = $_[ KERNEL ];
	my $date = strftime ("%Y-%m-%d", localtime(time - 3600*24));
	
    foreach (@channels) {
	    my $sth = $dbh->prepare_cached('SELECT COUNT(*) FROM playbot WHERE date = ? and chan = ?');
	    $log->error("Couldn't prepare querie; aborting") unless (defined $sth);
	    $sth->execute($date, $_)
		    or $log->error("Couldn't finish transaction: " . $dbh->errstr);
	    my ($nbr) = $sth->fetchrow_array;

	    if ($nbr) {
		    $irc->yield(privmsg => $_ => $nbr.' liens aujourd\'hui : '.$baseurl.$date);
	    }
    }

	$kernel->delay_set('_flux', 3600*24);
}


sub addTag
{
    my ($id, $tag) = @_;

    my $sth = $dbh->prepare_cached('INSERT INTO playbot_tags (id, tag) VALUES (?, ?)');
	$log->error("Couldn't prepare querie; aborting") unless (defined $sth);

	$sth->execute($id, $tag)
		or $log->error("Couldn't finish transaction: " . $dbh->errstr);
}
	

sub later
{
	my ($nick, $id) = @_[ARG0,ARG1];

	my $sth = $dbh->prepare_cached('SELECT url, sender, title FROM playbot WHERE id = ?');
	$log->error("Couldn't prepare querie; aborting") unless (defined $sth);

	$sth->execute($id)
		or $log->error("Couldn't finish transaction: " . $dbh->errstr);

	if ($sth->rows) {
		my @donnees = $sth->fetchrow_array;

		$irc->yield(privmsg => $nick => '['.$id.'] '.$donnees[2].' | '.$donnees[1]);
		$irc->yield(privmsg => $nick => $donnees[0]);
	}
}


sub cycle
{
	my ($arg) = @_;

	$log->info("restarting");
	$irc->yield(quit => 'goodbye');
	sleep 1;
	exec $bot;
}


## GESTION EVENTS

# Au démarrage
sub bot_start {
	$irc->yield(register => "all");
	$irc->yield(
		connect => {
			Nick     => $nick,
			Username => $username, 
			Ircname  => $ircname,
			Server   => $serveur,
			Port     => $port,
		}
	);
}


# A la connection
sub on_connect
{
	my $kernel = $_[ KERNEL ];

	$log->info('connected');

	foreach (@channels) {
		$irc->yield(join => $_);
		$log->info("join $_");
	}
	
	my $hour = strftime ('%H', localtime);
	my $min = strftime ('%M', localtime);

	$kernel->delay_set('_flux', (23-$hour)*3600 + (60-$min)*60);
}


# Discussion privée
sub on_query
{
	my ($user,$msg) = @_[ARG0, ARG2];
	my ($nick) = split (/!/,$user);
	print $msg."\n";

	if ($msg =~ m/^!/ && $nick eq $admin) {
		my $commande = ( $msg =~ m/^!([^ ]*)/ )[0]; 
		my @params = grep {!/^\s*$/} split(/\s+/, substr($msg, length("!$commande")));

		foreach (keys(%commandes_admin)) {
			if ($commande eq $_) {
				$commandes_admin{$_}->(@params);
				last;
			}
		}
	}
	elsif ($msg =~ /^PB/) {
		# on vérifie si le nick est register
		push (@nicksToVerify, $nick);
		push (@codesToVerify, $msg);
		$irc->yield(privmsg => $nick => 'Vérification en cours…');
		$irc->yield(privmsg => nickserv =>  'info '.$nick);
	}
}


sub on_notice
{
	my ($user, $msg) = @_[ARG0, ARG2];
	my ($nick) = split(/!/,$user);

	return unless ($nick =~ /^NickServ$/i);

	my $nickToVerify = shift @nicksToVerify;
	my $code = shift @codesToVerify;

	return unless (defined($nickToVerify));
	
	if ($msg !~ /$nickToVerify/) {
		push (@nicksToVerify, $nickToVerify);
		push (@codesToVerify, $code);
	}
	elsif ($msg =~ /isn't registered/) {
		$irc->yield(privmsg => $nickToVerify => "Il faut que ton pseudo soit enregistré auprès de NickServ");
	}
	else {
		my $sth = $dbh->prepare_cached('SELECT user FROM playbot_codes WHERE code = ?');
		$log->error("Counldn't prepare querie; aborting") unless (defined $sth);
		$sth->execute($code);

		if ($sth->rows) {
			my $sth = $dbh->prepare_cached('UPDATE playbot_codes SET nick = ? WHERE code = ?');
			$log->error("Couldn't prepare querie; aborting") unless (defined $sth);

			$sth->execute($nickToVerify, $code)
				or $log->error("Couldn't finish transaction: " . $dbh->errstr);
			
			$irc->yield(privmsg => $nickToVerify => 'Association effectuée');
			$irc->yield(privmsg => $nickToVerify => 'pour enregistrer un lien dans tes favoris : !fav <id>');
		}
		else {
			$irc->yield(privmsg => $nickToVerify => "Ce code n'existe pas");
		}
	}
}


# Quand un user parle
sub on_speak
{
	my ($kernel, $user, $chan, $msg) = @_[KERNEL, ARG0, ARG1, ARG2];
	my ($nick,$mask) = split(/!/,$user);
	my $site;
	my %content;

	if ($msg =~ m#(^|[^!])https?://(www.youtube.com/watch\?[a-zA-Z0-9_=&-]*v=|youtu.be/)([a-zA-Z0-9_-]+)#) {
		my $url = 'https://www.youtube.com/watch?v='.$3;
		eval { %content = youtube($url) };
		$site = 'youtube';
	}
	elsif ($msg =~ m#(^|[^!])https?://soundcloud.com/([a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+)#) {
		my $url = 'https://www.soundcloud.com/'.$2;
		eval { %content = soundcloud($url) };
		$site = 'soundcloud';
	}
	elsif ($msg =~ m#(^|[^!])https?://www.mixcloud.com/([a-zA-Z0-9-_]+/[a-zA-Z0-9-_]+)#) {
		my $url = 'https://www.mixcloud.com/'.$2;
		eval { %content = mixcloud($url) };
		$site = 'mixcloud';
	}
	elsif ($msg =~ m#((^|[^!])http://www[0-9]+.zippyshare.com/v/[0-9]+/file.html)#) {
		my $url = $1;
		eval { %content = zippy($url) };
		$site = 'zippyshare';
	}
	elsif ($msg =~ /^!fav( ([0-9]+))?/) {
		my $id = ($2) ? $2 : $lastID;

		my $sth = $dbh->prepare_cached('SELECT user FROM playbot_codes WHERE nick = ?');
		$sth->execute($nick)
			or $log->error("Couldn't finish transaction: " . $dbh->errstr);

		unless ($sth->rows) {
			$irc->yield(privmsg => $nick => "Ce nick n'est associé à aucun login arise. Va sur http://nightiies.iiens.net/links/fav pour obtenir ton code personel.");
			return;
		}

		my $sth2 = $dbh->prepare_cached('INSERT INTO playbot_fav (id, user) VALUES (?, ?)');
		$sth2->execute($id, $sth->fetch->[0])
			or $log->error("Couldn't finish transaction: " . $dbh->errstr);

		return;
	}
	elsif ($msg =~ /^!later( ([0-9]*)( in ([0-9]*)(h|m|s)?)?)?/) {
		my ($id, $time, $unit) = ($2, $4, $5);

		$id = $lastID if (!$id);
		$time = 6 if (!$time);
		$time *= ($unit eq 's') ? 1 : ($unit eq 'm') ? 60 : 3600;
		print "$time eq\n";
		$kernel->delay_set('_later', $time, $nick, $id);

		return;
	}
    elsif ($msg =~ /^!tag( +([0-9]+))?/) {
        my $id = ($2) ? $2 : $lastID;
        while ($msg =~ /#([a-zA-Z0-9_-]+)/g) {
            addTag($id, $1);
        }

        return;
    }
    elsif ($msg =~ /^!help/) {
		$irc->yield(privmsg => $chan => '!fav [<id>] : enregistre la vidéo dans les favoris');
		$irc->yield(privmsg => $chan => '!tag [<id>] <tag1> <tag2> ... : tag la vidéo');
		$irc->yield(privmsg => $chan => '!later [<id>] [in <x>[s|m|h]] : vidéo rappelée par query (par défaut temps de 6h)');
		$irc->yield(privmsg => $chan => 'Sans id précisée, la dernière vidéo postée est utilisée.');

        return;
    }
	else {
		return;
	}

	if ($@) {
		$log->warning ($@);
		return;
	}

	if ($debug) {
		$log->debug($content{'url'});
	}
	else {
		# insertion de la vidéo dans la bdd

		my $sth = $dbh->prepare_cached('INSERT INTO playbot (date, type, url, sender_irc, sender, title, chan) VALUES (NOW(),?,?,?,?,?,?)');
		$log->error("Couldn't prepare querie; aborting") unless (defined $sth);

		$sth->execute($site, $content{'url'}, $nick, $content{'author'}, $content{'title'}, $chan->[0])
			or $log->error("Couldn't finish transaction: " . $dbh->errstr);
	}

	# sélection de l'id de la vidéo insérée
	my $id = $dbh->{mysql_insert_id};
	if (!$id) {
		my $sth = $dbh->prepare_cached('SELECT id FROM playbot WHERE url = ?');
		$log->error("Couldn't prepare querie; aborting") unless (defined $sth);

		$sth->execute($content{'url'})
			or $log->error("Couldn't finish transaction: " . $dbh->errstr);

		$id = $sth->fetch->[0];
	}
	$lastID = $id;


	# insertion des éventuels tags
	while ($msg =~ /#([a-zA-Z0-9_-]+)/g) {
		if ($debug) {
			$log->debug($1);
			next;
		}

        addTag ($lastID, $1);
    }


	# message sur irc
	if (defined $content{'author'}) {
		$irc->yield(privmsg => $chan => '['.$id.'] '.$content{'title'}.' | '.$content{'author'}) ;
	}
	else {
		$irc->yield(privmsg => $chan => '['.$id.'] '.$content{'title'}) ;
	}
}


# Boucle des events
$poe_kernel->run();
exit 0;
