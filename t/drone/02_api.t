use strict;
use Test::More (tests => 2);

BEGIN
{
    use_ok("Swarmage::Drone");
}

can_ok("Swarmage::Drone", qw(new setup_log register_worker mark_worker_done postback monitor pump_queue));