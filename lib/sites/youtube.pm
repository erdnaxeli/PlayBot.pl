package youtube;

use WebService::GData::YouTube;
use URI::Find;
use Encode;
require Encode::Detect;

sub get {
	my $id = shift;

    my $yt = new WebService::GData::YouTube();
    my $video = $yt->get_video_by_id($id);

    my %infos;
    #$infos{'title'} = decode("UTF-8", $video->title);
    $infos{'title'} = $video->title;
    $infos{'author'} = $video->uploader;
	$infos{'url'} = $video->base_uri;
    $infos{'duration'} = $video->duration;

	return %infos;
}

1;
