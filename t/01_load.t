use strict;
use Test::More;

my @modules = qw(
    Swarmage
    Swarmage::Task
    Swarmage::Client
    Swarmage::Worker
    Swarmage::Queue
    Swarmage::Queue::Stomp
);

plan(tests => scalar @modules);
use_ok($_) for @modules;