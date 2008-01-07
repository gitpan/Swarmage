use strict;
use Test::More (tests => 2);

BEGIN
{
    use_ok("Swarmage::Queue::Local");
}

can_ok("Swarmage::Queue::Local", qw(new dequeue enqueue pump poll_wait));