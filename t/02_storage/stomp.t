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
        plan tests => 6;
        use_ok("Swarmage::Storage::Stomp");
    }
}

my $queue_id = join('.', 'swarmage_test', $$, int(rand() * 10000));
diag("Using temp queue $queue_id");
my $storage = Swarmage::Storage::Stomp->new(
    connect_info => {
        map { ($_ => $ENV{ uc "SWARMAGE_STOMP_$_" }) }
            qw(hostname port login passcode)
    }
);
ok($storage);
isa_ok($storage, 'Swarmage::Storage::Stomp');

my $task = Swarmage::Task->new(task_class => $queue_id);
my @fetch = $storage->fetch_queue($task->destination);
ok(! @fetch, "no task should be found");

ok( $storage->insert_queue( $task ), "successful send");
@fetch = $storage->fetch_queue($task->destination);
ok(scalar @fetch);

1;