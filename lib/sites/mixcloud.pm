package mixcloud;

use LWP::UserAgent;
use JSON;

sub get {
	my ($url) = @_;
    $url =~ s/www/api/;
    my %infos;

	my $ua = LWP::UserAgent->new(timeout => 30);
	my $response = $ua->get($url);
	die($response->status_line) unless ($response->is_success);

	$content = decode_json($response->decoded_content);
	$infos{'title'} = $content->{'name'};
	$infos{'author'} = $content->{'user'}->{'name'};
	$infos{'url'} = $content->{'url'};
    $infos{'duration'} = $content->{'audio_length'};

	return %infos;
}

1;
