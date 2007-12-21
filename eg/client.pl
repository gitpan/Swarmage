#!perl
use strict;
use lib 'lib';
use lib 't/lib';
use Swarmage::Client;

my $local_db = "t/swarmage.db";
my $client = Swarmage::Client->new(
    queue => {
        module => "DBI",
        config => {
            connect_info => [
                "dbi:SQLite:dbname=$local_db",
                undef,
                undef,
                { AutoCommit => 1, RaiseError => 1 },
            ]
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