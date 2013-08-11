package commands::later;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(exec);

sub exec {
    my ($kernel, $nick, $id, $time, $unit) = @_;

	$time = 6 if (!$time);
	$time *= ($unit eq 's') ? 1 : ($unit eq 'm') ? 60 : 3600;
	$kernel->delay_set('_later', $time, $nick, $id);
}

1;
