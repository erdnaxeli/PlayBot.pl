package utils::print;

use strict;

# Used to print a content.
# The public subroutine is print($content).
# arg :
#   - $content : a ref to a hash with the following keys :
#       - id
#       - title
#       - author
#       - duration (in seconds)
#       - url
#       - tags : a ref to a list of tags
# returns :
#   - a string well formated

sub print {
    my ($content) = @_;

    my $msg = '['.$content->{'id'}.'] '.$content->{'title'};

	if (defined $content->{'author'}) {
		$msg .= ' | '.$content->{'author'};
	}

    if (defined $content->{'duration'}) {
        my $h = int($content->{'duration'} / 3600);
        my $m = int(($content->{'duration'} % 3600) / 60);
        my $s = int(($content->{'duration'} % 3600) % 60);

        $msg .= ' (';
        $msg .= sprintf("%02d:", $h) if ($h > 0);
        $msg .= sprintf("%02d:", $m);
        $msg .= sprintf("%02d", $s);
        $msg .= ')';
    }

    $msg .= ' => '.$content->{'url'} if (defined $content->{'url'});

    if (defined $content->{'tags'}) {
        $msg .= ' '.$_ foreach (@{$content->{'tags'}});
    }

    return $msg;
}

1;
