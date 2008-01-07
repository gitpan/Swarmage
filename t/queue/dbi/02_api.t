use strict;
use Test::More (tests => 2);

BEGIN
{
    use_ok("Swarmage::Queue::DBI");
}

can_ok("Swarmage::Queue::DBI", qw(new dequeue enqueue pump poll_wait connect_info dbh prepare_db));