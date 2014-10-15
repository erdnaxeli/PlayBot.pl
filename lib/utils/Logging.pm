package Logging;

# ==============[ Classe pour gérer les logs correctement ]============== #
#  Date : 29/10/2010                                                      #
#  Auteur : TC                                                            #
# ======================================================================= #

use strict;
use warnings;

use Fcntl ':mode';


# ###
#  new
# Instancie la classe - un constructeur en somme
# ###
sub new
{
	my $class = shift;
	my $self = {
		_file    =>   shift,
		_colored =>   0,
		_pending =>   0,
		_utf8    =>   0,
		_right_align => shift,
	};
	
	bless $self, $class;
	
	# On active la couleur que si on est sur un terminal
	# C'est moche après pour les fichiers ou un less
	if($self->file eq "STDOUT")
	{
		$self->{"_colored"} = 1 if((stat(STDOUT))[2] & S_IFCHR);
	}
	elsif($self->file eq "STDERR")
	{
		$self->{"_colored"} = 1 if((stat(STDERR))[2] & S_IFCHR);
	}
	else
	{
		$self->{"_colored"} = 1 if((stat($self->file))[2] & S_IFCHR);
	}
	
	
	unless(defined $self->{"_right_align"})
	{
		$self->{"_right_align"} = 0;
	}
	
	return $self;
} # Fin new


# ###
#  file
# Renvoie/maj $self->{'_file'}
# ###
sub file
{
	my $self = shift;
	$self->{"_file"} = $_[0] if(defined($_[0]));
	return $self->{"_file"};
} # Fin file


# ###
#  colored
# Renvoie/maj $self->{'_colored'}
# ###
sub colored
{
	my $self = shift;
	$self->{"_colored"} = $_[0] if(defined($_[0]));
	return $self->{"_colored"};
} # Fin colored


# ###
#  pending
# Renvoie/maj $self->{'_pending'}
# ###
sub pending
{
	my $self = shift;
	$self->{"_pending"} = $_[0] if(defined($_[0]));
	return $self->{"_pending"};
} # Fin pending


# ###
#  utf8
# Renvoie/maj $self->{"_utf8"}
# ###
sub utf8
{
	my $self = shift;
	$self->{"_utf8"} = $_[0] if(defined($_[0]));
	return $self->{"_utf8"};
} # Fin utf8


# ###
#  right_align
# Renvoie/maj $self->{"_right_align"}
# ###
sub right_align
{
	my $self = shift;
	$self->{"_right_align"} = $_[0] if(defined($_[0]));
	return $self->{"_right_align"};
} # Fin right_align


# ###
#  debug
# Fonction gérant les logs du niveau debug (1)
# ###
sub debug
{
	my ($self, $text) = @_;
	return unless(defined $text);
	
	chomp $text;
	
	my $parent = ( caller(1) )[3];
	$parent = "" if(!defined($parent));
	
	if($self->colored)
	{
		$text = "\e[36mDEBUG\e[0m:$parent:$text";
	}
	else
	{
		$text = "DEBUG:$parent:$text";
	}
	
	return $self->print_in_file($text, $self->DEBUG);
} # Fin debug


# ###
#  pending_debug
# Fonction gérant les logs du niveau debug (1)
# ###
sub pending_debug
{
	my ($self, $text) = @_;
	chomp $text;
	
	my $parent = ( caller(1) )[3];
	$parent = "" if(!defined($parent));
	
	if($self->colored)
	{
		$text = "\e[36mDEBUG\e[0m:$parent:$text";
	}
	else
	{
		$text = "DEBUG:$parent:$text";
	}
	
	return $self->pending_in_file($text, $self->DEBUG);
} # Fin pending_debug


# ###
#  info
# Fonction gérant les logs du niveau info (2)
# ###
sub info
{
	my ($self, $text) = @_;
	return unless(defined $text);
	
	chomp $text;
	
	my $parent = ( caller(1) )[3];
	$parent = "" if(!defined($parent));
	
	if($self->colored)
	{
		$text = "\e[33;1mINFO\e[0m:$parent:$text";
	}
	else
	{
		$text = "INFO:$parent:$text";
	}
	
	return $self->print_in_file($text, $self->INFO);
} # Fin info


# ###
#  pending_info
# Fonction gérant les logs du niveau info (2)
# ###
sub pending_info
{
	my ($self, $text) = @_;
	return unless(defined $text);
	
	chomp $text;
	
	my $parent = ( caller(1) )[3];
	$parent = "" if(!defined($parent));
	
	if($self->colored)
	{
		$text = "\e[33;1mINFO\e[0m:$parent:$text";
	}
	else
	{
		$text = "INFO:$parent:$text";
	}
	
	return $self->pending_in_file($text, $self->INFO);
} # Fin pending_info


# ###
#  warning
# Fonction gérant les logs du niveau warning (3)
# ###
sub warning
{
	my ($self, $text) = @_;
	return unless(defined $text);
	
	chomp $text;
	
	my $parent = ( caller(1) )[3];
	$parent = "" if(!defined($parent));
	
	if($self->colored)
	{
		$text = "\e[33mWARNING\e[0m:$parent:$text";
	}
	else
	{
		$text = "WARNING:$parent:$text";
	}
	
	return $self->print_in_file($text, $self->WARNING);
} # Fin warning


# ###
#  pending_warning
# Fonction gérant les logs du niveau warning (3)
# ###
sub pending_warning
{
	my ($self, $text) = @_;
	return unless(defined $text);
	
	chomp $text;
	
	my $parent = ( caller(1) )[3];
	$parent = "" if(!defined($parent));
	
	if($self->colored)
	{
		$text = "\e[33mWARNING\e[0m:$parent:$text";
	}
	else
	{
		$text = "WARNING:$parent:$text";
	}
	
	return $self->pending_in_file($text, $self->WARNING);
} # Fin pending_warning


# ###
#  error
# Fonction gérant les logs du niveau error (4)
# ###
sub error
{
	my ($self, $text) = @_;
	return unless(defined $text);
	
	chomp $text;
	
	my $parent = ( caller(1) )[3];
	$parent = "" if(!defined($parent));
	
	if($self->colored)
	{
		$text = "\e[31mERROR\e[0m:$parent:$text";
	}
	else
	{
		$text = "ERROR:$parent:$text";
	}
	
	return $self->print_in_file($text, $self->ERROR);
} # Fin error


# ###
#  pending_error
# Fonction gérant les logs du niveau error (4)
# ###
sub pending_error
{
	my ($self, $text) = @_;
	return unless(defined $text);
	
	chomp $text;
	
	my $parent = ( caller(1) )[3];
	$parent = "" if(!defined($parent));
	
	if($self->colored)
	{
		$text = "\e[31mERROR\e[0m:$parent:$text";
	}
	else
	{
		$text = "ERROR:$parent:$text";
	}
	
	return $self->pending_in_file($text, $self->ERROR);
} # Fin pending_error


# ###
#  critical
# Fonction gérant les logs du niveau critical (5)
# ###
sub critical
{
	my ($self, $text) = @_;
	return unless(defined $text);
	
	chomp $text;
	
	my $parent = ( caller(1) )[3];
	$parent = "" if(!defined($parent));
	
	if($self->colored)
	{
		$text = "\e[31;1mCRITICAL\e[0m:$parent:$text";
	}
	else
	{
		$text = "CRITICAL:$parent:$text";
	}
	
	return $self->print_in_file($text, $self->CRITICAL);
} # Fin critical


# ###
#  pending_critical
# Fonction gérant les logs du niveau critical (5)
# ###
sub pending_critical
{
	my ($self, $text) = @_;
	return unless(defined $text);
	
	chomp $text;
	
	my $parent = ( caller(1) )[3];
	$parent = "" if(!defined($parent));
	
	if($self->colored)
	{
		$text = "\e[31;1mCRITICAL\e[0m:$parent:$text";
	}
	else
	{
		$text = "CRITICAL:$parent:$text";
	}
	
	return $self->pending_in_file($text, $self->CRITICAL);
} # Fin pending_critical


# ###
#  print_in_file
# Écrit dans le fichier
# ###
sub print_in_file
{
	my ($self, $text, $level) = @_;
	return unless(defined $text);
	
	chomp $text;
	$text = "[\e[32m" . (scalar localtime time) . "\e[0m] $text";
	
	$self->end_pending(0, $level) if($self->pending);
	
	if($self->file eq "STDOUT")
	{
		print STDOUT $text."\n";
	}
	elsif($self->file eq "STDERR")
	{
		print STDERR $text."\n";
	}
	else
	{
		open LOG, ">>", $self->file or return 0;
		print LOG $text."\n";
		close LOG;
		
		print $text."\n" if(defined($level) && $Config::debug >= $level);
	}
	
	return 1;
} # Fin print_in_file


# ###
#  pending_in_file
# Écrit dans le fichier en attendant de savoir si ça a réussi ou pas
# ###
sub pending_in_file
{
	my ($self, $text, $level) = @_;
	return unless(defined $text);
	
	chomp $text;
	$text = "[" . (scalar localtime time) . "] $text";
	
	if($self->file eq "STDOUT")
	{
		if($self->right_align)
		{
			printf STDOUT "%-90s", $text;
		}
		else
		{
			print STDOUT $text;
		}
	}
	elsif($self->file eq "STDERR")
	{
		if($self->right_align)
		{
			printf STDERR "%-90s", $text;
		}
		else
		{
			print STDERR $text;
		}
	}
	else
	{
		if($self->right_align)
		{
			open LOG, ">>", $self->file or return 0;
			printf LOG "%-90s", $text;
			close LOG;
			
			printf "%-90s", $text if(defined($level) && $Config::debug >= $level);
		}
		else
		{
			open LOG, ">>", $self->file or return 0;
			print LOG $text;
			close LOG;
			
			print $text if(defined($level) && $Config::debug >= $level);
		}
	}
	
	$self->pending(1);
	
	return 1;
} # Fin pending_in_file


# ###
#  end_pending
# Écrit dans le fichier le résultat de l'attente
# ###
sub end_pending
{
	my ($self, $done_or_error, $level) = @_;
	
	my $done = "";
	
	if($done_or_error)
	{
		if($self->colored)
		{
			$done = sprintf "%c[32m Done ", 0x1B;
		}
		else
		{
			$done = sprintf " Done \n";
		}
		
		$done .= "☑" if($self->utf8);
	}
	else
	{
		if($self->colored)
		{
			$done = sprintf "%c[31m Error ", 0x1B;
		}
		else
		{
			$done = sprintf " Error \n";
		}
		
		$done .= "☒" if($self->utf8);
	}
	
	$done .= "\e[0m\n" if($self->colored);
	
	
	# À partir d'ici, $done peut vouloir dire que c'est bon, ou pas
	if($self->file eq "STDOUT")
	{
		printf STDOUT $done;
	}
	elsif($self->file eq "STDERR")
	{
		printf STDERR $done;
	}
	else
	{
		open LOG, ">>", $self->file or return 0;
		printf LOG $done;
		close LOG;
		
		printf $done if(defined($level) && $Config::debug >= $level);
	}
	
	
	$self->pending(0);
	
	return 1;
} # Fin end_pending


#
# Fonctions pour récupérer les différents niveaux de debug
#
sub DEBUG   { return 3; }
sub INFO    { return 2; }
sub WARNING { return 1; }
sub ERROR   { return 0; }
sub CRITICAL { return -1; }
# Pour ceux qui préfèrent utiliser des variables...
our $DEBUG    = 3;
our $INFO     = 2;
our $WARNING  = 1;
our $ERROR    = 0;
our $CRITICAL = -1;
our %LVL_NAME = (
	"DEBUG"    => 3,
	"INFO"     => 2,
	"WARNING"  => 1,
	"ERROR"    => 0,
	"CRITICAL" => -1
);

# Et dans l'autre sens
sub LVL
{
	my ($self, $num) = @_;
	
	my %LVL = (
		3    => "DEBUG",
		2    => "INFO",
		1    => "WARNING",
		0    => "ERROR",
		"-1" => "CRITICAL"
	);
	
	return $LVL{$num};
}
our %LVL = (
	3    => "DEBUG",
	2    => "INFO",
	1    => "WARNING",
	0    => "ERROR",
	"-1" => "CRITICAL"
);


# ###
#  dbg
# Imprime des infos de debug à l'écran (STDOUT)
# ###
sub dbg
{
	my $self = shift;
	
	require Data::Dumper;
	print Data::Dumper->Dump([$self], [qw(Logging)]);
} # Fin dbg


1;

__END__

