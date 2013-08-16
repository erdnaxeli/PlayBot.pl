package soundcloud;

use LWP::UserAgent;
use JSON;
use URI::Find;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(soundcloud);


my $root = 'http://api.soundcloud.com';
my $clientId = 'f4956716fe1a9dc9c3725af822963365';


sub get {
	my ($url) = @_;

	my $ua = LWP::UserAgent->new(timeout => 30);

	my $response = $ua->get($root.'/resolve.json?url='.$url.'&client_id='.$clientId);
	die($response->status_line) unless ($response->is_success);

	$content = decode_json($response->decoded_content);
	$infos{'title'} = $content->{'title'};
	$infos{'author'} = $content->{'user'}->{'username'};
	$infos{'url'} = $url;

	if ($content->{'downloadable'}) {
		$infos{'ddl'} = $content->{'download_url'};
	}
    
    my $context = $content->{'tag_list'}.' '.$content->{'description'}.' '.$infos{'title'};
    my $finder = URI::Find->new( sub { '' } );

    # we remove the URI and the punctuation
    $finder->find(\$context);
    $context =~ s/[[:punct:]]//g;

    $infos{'context'} = $context;
	
	return %infos;
}

1;
