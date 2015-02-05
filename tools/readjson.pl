#!/usr/bin/perl -w

use strict;

use JSON;
use POE;
use POE::Component::IKC::Client;
use FindBin;

POE::Component::IKC::Client->spawn(
    unix => "$FindBin::Bin/../playbot.sock",
    name => "client-$$",
    on_connect => \&on_connect
);

POE::Component::IKC::Responder->spawn();
POE::Kernel->run();
exit;

sub on_connect {
    POE::Session->create(
        inline_states => {
            _start => \&on_start,
            send   => \&on_send
        }
    );
}

sub on_start {
    print "start\n";
    my $kernel = $_[KERNEL];

    # we 'slurp' stdin
    local $/;
    my $json = <>;
    my $content = decode_json $json;
    print "$json\n";

    # TODO: handle $content->{'msg'}
    $kernel->post('IKC', 'post', 'poe://PlayBot/fbrecv/fbmsg', [ $content->{'author'}, $content->{'msg'} ]);
    $kernel->post('IKC', 'shutdown');
}
