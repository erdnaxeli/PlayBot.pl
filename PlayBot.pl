#!/usr/bin/perl -w
use strict;
use warnings;

use POE;
use POE::Component::IRC;
use POSIX 'strftime';
use DBI;
use Tie::File;
use JSON;
use Module::Reload;
use FindBin;

use lib "$FindBin::Bin/lib/";
use Logging;
use sites::parser;
use commands::parser;

# nom du fichier
my $bot = $0;

my $log = Logging->new('STDOUT', 1);

# config
my $serveur = 'IRC.iiens.net';
my $nick = 'PlayBot';
my $port = 6667;
my $ircname = 'nightiies';
my $username = 'nightiies';
my @channels = qw(#nightiies #dansiie #pimpim #vitamine #fanfare #groop #bigphatsubwoofer);
my $admin = 'moise';
my $baseurl = 'http://nightiies.iiens.net/links/';
my @nicksToVerify;
my @codesToVerify;
my %lastID;

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
        irc_invite => \&on_invite,
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
	    my $sth = $dbh->prepare_cached('
            SELECT COUNT(*)
            FROM playbot p
            JOIN playbot_chan pc ON p.id = pc.content
            WHERE date = ? and chan = ?');
	    $log->error("Couldn't prepare querie; aborting") unless (defined $sth);
	    $sth->execute($date, $_)
		    or $log->error("Couldn't finish transaction: " . $dbh->errstr);
	    my ($nbr) = $sth->fetchrow_array;

	    if ($nbr) {
		    $irc->yield(privmsg => $_ => $nbr.' liens aujourd\'hui : '.$baseurl . substr ($_, 1) . '/' . $date);
	    }
    }

	$kernel->delay_set('_flux', 3600*24);
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
    
	    $lastID{$nick} = $id;
	}
}


sub cycle
{
	my ($arg) = @_;

	$log->info("refresh modules");

    Module::Reload->check;

    setConf();
}


sub setConf 
{
    commands::parser::setConf($irc, $dbh, $log, \%lastID);

    $sites::parser::dbh = $dbh;
    $sites::parser::irc = $irc;
    $sites::parser::log = $log;
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

    setConf();
    $irc->yield(privmsg => "NickServ" => "identify ".$conf->{'nickserv_pwd'}) unless ($debug);
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
	my ($kernel, $user, $msg) = @_[KERNEL, ARG0, ARG2];
	my ($nick) = split (/!/,$user);

    my @fake_chan = ($nick);
    my @args = ($kernel, $user, \@fake_chan, $msg);

    my $fake_chan = \@fake_chan;
    return if (commands::parser::exec(@args));

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

# Quand on m'invite, je join
sub on_invite
{
	my ($kernel, $user, $chan) = @_[KERNEL, ARG0, ARG1];
	my ($nick,$mask) = split(/!/,$user);

	$log->info($nick . " m'invite sur ". $chan);
	$irc->yield(join => $chan);

    push @channels, $chan;
}

# Quand un user parle
sub on_speak
{
	my ($kernel, $user, $chan, $msg) = @_[KERNEL, ARG0, ARG1, ARG2];
    my @args = ($kernel, $user, $chan, $msg);

	my ($nick,$mask) = split(/!/,$user);
	my %content;

    # first we test if it's a command
    if (!commands::parser::exec(@args)) {
        # if not, maybe there is an url we can parse
	    my $id = sites::parser::parse(@args);

        # if there is a new content, there is a new id to save
        if ($id) {
            $lastID{$chan->[0]} = $id;
	    
            # we insert the potiential tags
            commands::parser::tag($msg, $chan);
        }
    }	
}

# Boucle des events
$poe_kernel->run();
exit 0;
