use strict;
use Test::More;
BEGIN
{
    if( ! $ENV{SWARMAGE_STOMP_HOSTNAME} ||
        ! $ENV{SWARMAGE_STOMP_PORT}     ||
        ! $ENV{SWARMAGE_STOMP_LOGIN}    ||
        ! $ENV{SWARMAGE_STOMP_PASSCODE}
    ) {
        plan skip_all => "Define SWARMAGE_STOMP_HOSTNAME, SWARMAGE_STOMP_PORT, SWARMAGE_STOP_LOGIN, and SWARMAGE_STOMP_PASSCODE to run these tests";
    } else {
        plan tests => 7;
        use_ok("Swarmage::Queue::Stomp");
    }
}

my $queue_id = join('.', 'swarmage_test', $$, int(rand() * 10000));
diag("Using temp queue $queue_id");
my $queue = Swarmage::Queue::Stomp->new(
    read_delay => '0.001',
    connect_info => {
        map { ($_ => $ENV{ uc "SWARMAGE_STOMP_$_" }) }
            qw(hostname port login passcode)
    }
);
ok($queue);
isa_ok($queue, 'Swarmage::Queue::Stomp');
is($queue->read_delay, '0.001');

my $task = Swarmage::Task->new(task_class => $queue_id);
my @fetch = $queue->fetch(queue => $task->destination);
ok(! @fetch, "no task should be found");

ok( $queue->insert( message => $task ), "successful send");
@fetch = $queue->fetch(queue => $task->destination);
ok(scalar @fetch);

1;

