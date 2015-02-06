package utils::print;

use strict;

use IRC::Utils qw(YELLOW ORANGE GREEN NORMAL LIGHT_BLUE GREY);

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

    my $msg = YELLOW.'['.$content->{'id'}.'] '.GREEN.$content->{'title'};

	if (defined $content->{'author'}) {
		$msg .= ' | '.$content->{'author'};
	}

    if (defined $content->{'duration'}) {
        my $h = int($content->{'duration'} / 3600);
        my $m = int(($content->{'duration'} % 3600) / 60);
        my $s = int(($content->{'duration'} % 3600) % 60);

        $msg .= LIGHT_BLUE.' (';
        $msg .= sprintf("%02d:", $h) if ($h > 0);
        $msg .= sprintf("%02d:", $m);
        $msg .= sprintf("%02d", $s);
        $msg .= ')'.NORMAL;
    }

    $msg .= ' => '.$content->{'url'}.ORANGE if (defined $content->{'url'});

    if (defined $content->{'tags'}) {
        $msg .= ' '.$_ foreach (@{$content->{'tags'}});
    }

    $msg .= GREY;

    return $msg;
}

1;
