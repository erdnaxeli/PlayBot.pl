package zippy;

use LWP::UserAgent;
use HTML::Parser;
use HTML::Entities;

my $inTitle = 0;
my $inAuthor = 0;
my %infos;


sub get {
	my ($url) = @_;

	my $ua = LWP::UserAgent->new(
		agent   => "Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US; rv:1.9.2.13) Gecko/20101203 Firefox/3.6.13 GTB7.1",
		timeout => 30
	);

	my $response = $ua->get($url);
	die($response->status_line) unless ($response->is_success);

	my $content = $response->decoded_content;

	my $parser = HTML::Parser->new();
	$parser->handler(text => \&parser_text, 'text');
	$parser->handler(start => \&parser_start, 'tagname');
	$parser->handler(end => \&parser_end, 'tagname');
	$parser->unbroken_text(1);
	$parser->report_tags('title', 'a');
	$parser->parse($content);
	$parser->eof();
	
	$infos{'url'} = $url;
	$infos{'author'} = undef;
	
	return %infos;
}

sub parser_text
{
	my ($text) = @_;
	chomp $text;
	$text = decode_entities($text);

	if ($inTitle) {
		$text =~ s/^Zippyshare.com - //;
		$text =~ s/\.mp3$//;
		$infos{'title'} = $text;
	}
}

sub parser_start
{
	my ($tag) = @_;
	$inTitle = 1 if ($tag eq 'title');
}

sub parser_end
{
	my ($tag) = @_;
	$inTitle = 0 if ($tag eq 'title');
}

1;
