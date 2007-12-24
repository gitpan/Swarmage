#!perl
use strict;
use lib "lib";
use lib "t/lib";
use Swarmage::Drone;

Swarmage::Drone->new(
    queue => {
        module => 'BerkeleyDB',
        config => {
            filename => "eg/queue.db"
        }
    },
    workers => {
        factorial => [
            {
                module => '+SwarmageTest::Worker::Factorial',
            },
            {
                module => '+SwarmageTest::Worker::Factorial',
            },
            {
                module => '+SwarmageTest::Worker::Factorial',
            },
        ],
        hexadecimal => [
            {
                module => '+SwarmageTest::Worker::Hexadecimal'
            },
            {
                module => '+SwarmageTest::Worker::Hexadecimal'
            },
            {
                module => '+SwarmageTest::Worker::Hexadecimal'
            },
        ]
    }
);
POE::Kernel->run;