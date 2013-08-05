package youtube;

use LWP::UserAgent;
use HTML::Parser;
use HTML::Entities;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(youtube);


my $inTitle = 0;
my $inAuthor = 0;
my %infos;


sub youtube {
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
	$parser->handler(start => \&parser_start, 'tagname,attr');
	$parser->handler(end => \&parser_end, 'tagname');
	$parser->unbroken_text(1);
	$parser->report_tags('title', 'a');
	$parser->parse($content);
	$parser->eof();
	
	$infos{'url'} = $url;
	
	return %infos;
}

sub parser_text
{
	my ($text) = @_;
	chomp $text;

	if ($inTitle) {
		$text =~ s/\n//;
		$text =~ s/- YouTube//;
		$text =~ s/^ *//;
		$text =~ s/[^a-zA-Z0-9\(\)\[\]]*$//;
		$infos{'title'} = decode_entities($text);
	}
	elsif ($inAuthor) {
		$infos{'author'} = $text;
	}
}

sub parser_start
{
	my ($tag, $attr) = @_;
	$inTitle = 1 if ($tag eq 'title');
	return unless (defined $attr);
	$inAuthor = 1 if ($tag eq 'a' && exists($attr->{'class'}) && $attr->{'class'} =~ /yt-user-name author/);
}

sub parser_end
{
	my ($tag) = @_;
	$inTitle = 0 if ($tag eq 'title');
	$inAuthor = 0 if ($tag eq 'a');
}

1;
