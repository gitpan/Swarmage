use strict;
use Test::More;
use lib("t/lib");

BEGIN
{
    if( ! $ENV{SWARMAGE_STOMP_HOSTNAME} ||
        ! $ENV{SWARMAGE_STOMP_PORT}     ||
        ! $ENV{SWARMAGE_STOMP_LOGIN}    ||
        ! $ENV{SWARMAGE_STOMP_PASSCODE}
    ) {
        plan skip_all => "Define SWARMAGE_STOMP_HOSTNAME, SWARMAGE_STOMP_PORT, SWARMAGE_STOMP_LOGIN, and SWARMAGE_STOMP_PASSCODE to run these tests";
    } else {
        plan tests => 5;
        use_ok("Swarmage::Client");
        use_ok("SwarmageTest::Worker::Sum");
    }
}

my $queue_id = "sum";
diag("Using temp queue $queue_id");
my $client   = Swarmage::Client->new(
    queues => [
        {   class => 'Stomp',
            connect_info => {
                map { ($_ => $ENV{ uc "SWARMAGE_STOMP_$_" }) }
                    qw(hostname port login passcode)
            }
        },
    ]
);
my $worker   = SwarmageTest::Worker::Sum->new(
    queues => [
        {   class        => 'Stomp',
            connect_info => {
              map { ($_ => $ENV{ uc "SWARMAGE_STOMP_$_" }) }
                  qw(hostname port login passcode)
            }
        },
    ],
);

my $task = Swarmage::Task->new(
    task_class => $queue_id,
    data => { id => $$, arg1 => 9, arg2 => 3 },
    postback => "$queue_id.postback"
);
ok($client->insert_task($task), "insert ok");

$worker->work;

my ($message) = $client->find_task('/queue/sum.postback');
ok($message, "postback message ok");
is($message->data, $task->data->{arg1} + $task->data->{arg2}, "postback result ok (data = " . $message->data . ")");

1;