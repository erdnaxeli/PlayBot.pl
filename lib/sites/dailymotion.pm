package dailymotion;

use Inline Python => 'DATA';

sub get {
	my $id = shift;
    my $content = weboob_get($id);

    # weboob returns duration in h:mm:s format
    my ($h, $m, $s) = ($content->{'duration'} =~ /(.):(..):(..)/);
    $content->{'duration'} = $h * 3600 + $m * 60 + $s;

    return %{$content};
}

1;


__DATA__
__Python__

from weboob.core import Weboob
from weboob.capabilities.video import CapVideo

def weboob_get(id):
    w = Weboob()
    backends = w.load_backends(CapVideo)

    video = backends['dailymotion'].get_video(id)

    return {'title': video.title,
            'author': video.author,
            'url': video.url,
            'duration': video.duration}
