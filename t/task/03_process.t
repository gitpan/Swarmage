use strict;
use lib("t/lib");
use SwarmageTest::Task::Process;
use Test::More (tests => 2);

BEGIN
{
    use_ok("Swarmage::Task");
}

my $task = Swarmage::Task->new(
    type => 'process',
    data => SwarmageTest::Task::Process->new(number => 5)
);

$task->data->run;
is($task->data->{result}, 50);