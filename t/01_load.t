use strict;
use Test::More;

my @modules = qw(
    Swarmage::Drone
    Swarmage::Queue::DBI::Generic
    Swarmage::Queue::DBI
    Swarmage::Queue::Local::Generic
    Swarmage::Queue::Local
    Swarmage::Task
    Swarmage::Util
    Swarmage::Worker
    Swarmage
);
plan(tests => scalar @modules);
use_ok($_) for @modules;