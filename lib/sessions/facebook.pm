package sessions::facebook;

# This session have only one event to receive a message from the Facebook
# group. The args are, in order :
#   - the sender
#   - the msg (wich should contain a link, but is not mandatory)

use strict;
use warnings;

use POE;
use POE::Component::IKC::Server;
use FindBin;

use lib "$FindBin::Bin/lib/";
use utils::Logging;

my $log = Logging->new('STDOUT', 1);

POE::Component::IKC::Server->spawn(
    unix => 'playbot.sock',
    name => 'PlayBot'
);

POE::Session->create(
	inline_states => {
        _start => \&on_start,
        fbmsg  => \&on_fbmsg
    }
);

sub on_start {
    my $kernel = $_[KERNEL];
    $kernel->alias_set('fbrecv');
    $kernel->post(IKC => publish => 'fbrecv', ['fbmsg']);

    $log->info('listening for clients');
}

sub on_fbmsg {
    my ($kernel, $args) = @_[KERNEL, ARG0];
    $kernel->post('bot' => 'irc_public' => $args->[0], ['#nightiies.facebook'], $args->[1]);
}

1;
