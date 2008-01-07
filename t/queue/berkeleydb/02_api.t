use strict;
use Test::More (tests => 2);

BEGIN
{
    use_ok("Swarmage::Queue::BerkeleyDB");
}

can_ok("Swarmage::Queue::BerkeleyDB", qw(new dequeue enqueue pump poll_wait backend filename task_ids));