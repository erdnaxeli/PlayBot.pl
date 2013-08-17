package youtube;

use WebService::GData::YouTube;
use URI::Find;
use Encode;
require Encode::Detect;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(youtube);

sub get {
	my $id = shift;

    my $yt = new WebService::GData::YouTube();
    my $video = $yt->get_video_by_id($id);

    my %infos;
    $infos{'title'} = decode("Detect", $video->title);
    $infos{'author'} = $video->uploader;
	$infos{'url'} = $video->base_uri;

    my $context = decode("Detect", $video->description) . ' ' . $infos{'title'};
    my $finder = URI::Find->new( sub { '' } );

    # we remove the URI and the punctuation
    $finder->find(\$context);
    $context =~ s/[[:punct:]]//g;

    $infos{'context'} = $context;

	return %infos;
}

1;
