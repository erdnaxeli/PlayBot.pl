package youtube;

use WebService::GData::YouTube;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(youtube);

sub youtube {
	my $id = shift;

    my $yt = new WebService::GData::YouTube();
    my $video = $yt->get_video_by_id($id);

    my %infos;
    $infos{'title'} = $video->title;
    $infos{'author'} = $video->uploader;
	$infos{'url'} = $video->base_uri;
	
	return %infos;
}

1;
