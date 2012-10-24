#!/usr/bin/perl -w
use strict;
use warnings;
use POE;
use POE::Component::IRC;
use POSIX 'strftime';
use DBI;
use Tie::File;

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
my $channel = '#nightiies';
my $admin = 'moise';
my $baseurl = 'http://nightiies.iiens.net/links/';
my @nicksToVerify;
my @codesToVerify;

my $debug = 0;

# mode debug
if ($#ARGV + 1) {
	$channel = "#hormone";
	$nick = 'kikoo';
	$debug = 1;
}


## CONNEXION 
my ($irc) = POE::Component::IRC->spawn();
my $dbh = DBI->connect('DBI:mysql:assoce_nightiies;host=mysql.iiens.net', 'assoce_nightiies', 'POiREAU.jKNCFfBRq', {
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
		_flux	   => \&flux
	},
);


my %commandes_admin = ("cycle" => \&cycle);



### FONCTIONS
sub flux
{
	my $kernel = $_[ KERNEL ];
	my $date = strftime ("%Y-%m-%d", localtime(time - 3600*24));
	
	my $sth = $dbh->prepare_cached('SELECT COUNT(*) FROM playbot WHERE date = ?');
	$log->error("Couldn't prepare querie; aborting") unless (defined $sth);
	$sth->execute($date)
		or $log->error("Couldn't finish transaction: " . $dbh->errstr);
	my ($nbr) = $sth->fetchrow_array;

	if ($nbr) {
		$irc->yield(privmsg => $channel => $nbr.' liens aujourd\'hui : '.$baseurl.$date);
	}

	$kernel->delay_set('_flux', 3600*24);
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
	$irc->yield(join => $channel);
	$log->info('connected');
	
	my $hour = strftime ('%H', localtime);
	my $min = strftime ('%M', localtime);

	$kernel->delay_set('_flux', (23-$hour)*3600 + (60-$min)*60);
}


# Discussion privée
sub on_query
{
	my ($user,$msg) = @_[ARG0, ARG2];
	my ($nick) = split (/!/,$user);

	if ($msg =~ m/^!/ && $user eq $admin) {
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

	print $nick.' : '.$msg."\n";
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
		$log->info("ahahahah".$code);
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
	elsif ($msg =~ m#(^|[^!])https?://soundcloud.com/([a-zA-Z0-9-]+/[a-zA-Z0-9-]+)#) {
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
	elsif ($msg =~ /!fav ([0-9]+)/) {
		my $sth = $dbh->prepare_cached('INSERT INTO playbot_fav (id, user) SELECT ?, user FROM playbot_codes WHERE nick = ?');
		$sth->execute($1, $nick)
			or $log->error("Couldn't finish transaction: " . $dbh->errstr);
		$irc->yield(privmsg => $chan => 'Ok');

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
		my $sth = $dbh->prepare_cached('INSERT INTO playbot (date, type, url, sender_irc, sender, title, chan) VALUES (NOW(),?,?,?,?,?,?)');
		$log->error("Couldn't prepare querie; aborting") unless (defined $sth);

		$sth->execute($site, $content{'url'}, $nick, $content{'author'}, $content{'title'}, '#nightiies')
			or $log->error("Couldn't finish transaction: " . $dbh->errstr);
	}

	if (defined $content{'author'}) {
		$irc->yield(privmsg => $chan => '['.$dbh->{mysql_insertid}.'] '.$content{'title'}.' | '.$content{'author'}) ;
	}
	else {
		$irc->yield(privmsg => $chan => '['.$dbh->{mysql_insertid}.'] '.$content{'title'}) ;
	}
}


# Boucle des events
$poe_kernel->run();
exit 0;
