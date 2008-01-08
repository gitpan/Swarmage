use strict;
use lib 'lib';
use lib 't/lib';
use Swarmage::Drone;

Swarmage::Drone->new(
    queue => {
        module => 'IKC::Client',
        config => {
            remote_ip => '127.0.0.1',
            remote_port => 9999,
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