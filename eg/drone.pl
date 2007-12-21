#!perl
use strict;
use lib "lib";
use lib "t/lib";
use Swarmage::Drone;

my $local_db = "t/swarmage.db";
if (! -f $local_db) {
    my $dbh = DBI->connect(
        "dbi:SQLite:dbname=$local_db",
        undef,
        undef,
        { RaiseError => 1, AutoCommit => 1 }
    );
    $dbh->do(<<"    EOSQL");
        CREATE TABLE queues (
                    id          TEXT PRIMARY KEY,
                    task_type   TEXT NOT NULL,
                    task_data   TEXT NOT NULL,
                    taken_by    TEXT,
                    taken_on    NUMERIC,
                    modified_on NUMERIC,
                    inserted_on NUMERIC NOT NULL
        );
    EOSQL
    $dbh->disconnect;
}

Swarmage::Drone->new(
    queue => {
        module => 'DBI::Generic',
        config => {
            connect_info => [
                "dbi:SQLite:dbname=$local_db",
                undef,
                undef,
                { RaiseError => 1, AutoCommit => 1 }
            ]
        }
    },
    workers => {
        factorial => [
            {
                module => '+SwarmageTest::Worker::Factorial',
            }
        ],
        hexadecimal => [
            {
                module => '+SwarmageTest::Worker::Hexadecimal'
            }
        ]
    }
);
POE::Kernel->run;

BEGIN
{
    unlink $local_db;
}