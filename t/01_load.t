use strict;
use Test::More;

my @modules = qw(
    Swarmage
    Swarmage::Task
    Swarmage::Client
    Swarmage::Queue::DBI
    Swarmage::Queue::Local
    Swarmage::Queue::BerkeleyDB
    Swarmage::Queue::Generic
    Swarmage::Task
    Swarmage::Util
    Swarmage::Worker
    Swarmage::Worker::Generic
    Swarmage
);

plan(tests => scalar @modules);
use_ok($_) for @modules;