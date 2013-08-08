package parser;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(parse);

use lib "$FindBin::Bin/lib/sites/";
use youtube qw(youtube);
use soundcloud qw(soundcloud);
use mixcloud qw(mixcloud);
use zippy qw(zippy);


sub parse {
    my $msg = @_[0];
    my %content;

    if ($msg =~ m#(^|[^!])https?://(www.youtube.com/watch\?[a-zA-Z0-9_=&-]*v=|youtu.be/)([a-zA-Z0-9_-]+)#) {
		my $url = 'https://www.youtube.com/watch?v='.$3;
		eval { %content = youtube($url) };
		$content{'site'} = 'youtube';
	}
	elsif ($msg =~ m#(^|[^!])https?://soundcloud.com/([a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+)#) {
		my $url = 'https://www.soundcloud.com/'.$2;
		eval { %content = soundcloud($url) };
		$content{'site'} = 'soundcloud';
	}
	elsif ($msg =~ m#(^|[^!])https?://www.mixcloud.com/([a-zA-Z0-9-_]+/[a-zA-Z0-9-_]+)#) {
		my $url = 'https://www.mixcloud.com/'.$2;
		eval { %content = mixcloud($url) };
		$content{'site'} = 'mixcloud';
	}
	elsif ($msg =~ m#((^|[^!])http://www[0-9]+.zippyshare.com/v/[0-9]+/file.html)#) {
		my $url = $1;
		eval { %content = zippy($url) };
		$content{'site'} = 'zippyshare';
	}

    return %content;
}
