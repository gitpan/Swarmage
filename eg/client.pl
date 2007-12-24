#!perl
use strict;
use lib 'lib';
use lib 't/lib';
use Swarmage::Client;

my $client = Swarmage::Client->new(
    queue => {
        module => "BerkeleyDB",
        config => {
            filename => "eg/queue.db"
        }
    }
);

foreach my $data (1..10) {
    my ($response) = $client->post_respond( Swarmage::Task->new(
        type => "factorial",
        data => $data
    ) );

    print STDERR "Response = $response\n";
}
