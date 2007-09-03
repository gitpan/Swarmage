use strict;
use Test::More;

BEGIN
{
    if( ! $ENV{SWARMAGE_STOMP_HOSTNAME} ||
        ! $ENV{SWARMAGE_STOMP_PORT}     ||
        ! $ENV{SWARMAGE_STOMP_LOGIN}    ||
        ! $ENV{SWARMAGE_STOMP_PASSCODE}
    ) {
        plan skip_all => "Define SWARMAGE_STOMP_HOSTNAME, SWARMAGE_STOMP_PORT, SWARMAGE_STOMP_LOGIN, and SWARMAGE_STOMP_PASSCODE to run these tests";
    } else {
        plan tests => 8;
        use_ok("Swarmage::Client");
        use_ok("Swarmage::Worker");
    }
}

my $queue_id = join('.', 'swarmage_test', $$, int(rand() * 10000));
diag("Using temp queue $queue_id");
my $client   = Swarmage::Client->new(
    storage => [
        {   class => 'Stomp',
            connect_info => {
                map { ($_ => $ENV{ uc "SWARMAGE_STOMP_$_" }) }
                    qw(hostname port login passcode)
            }
        },
    ]
);
my $worker   = Swarmage::Worker->new(
    ability => [ $queue_id ],
    storage => [
        {   class        => 'Stomp',
            connect_info => {
              map { ($_ => $ENV{ uc "SWARMAGE_STOMP_$_" }) }
                  qw(hostname port login passcode)
            }
        },
    ],
    callbacks => {
        work      => sub {
            my ($self, $task) = @_;
            ok($task, "received task");
            is($task->task_class, $queue_id, "is the correct message");
            is($task->data->{id}, $$, "is the correct value"); 

            return $task->data->{arg1} + $task->data->{arg2};
        },
        post_work => sub { shift->is_running(0) }
    }
);

my $task = Swarmage::Task->new(
    task_class => $queue_id,
    data => { id => $$, arg1 => 5, arg2 => 3 },
    postback => "$queue_id.postback"
);
ok($client->insert_task($task), "insert ok");

$worker->work;

my $message = $client->storage_list->[0]->fetch_queue("$queue_id.postback");
ok($message, "postback message ok");
is($message->data, $task->data->{arg1} + $task->data->{arg2}, "postback result ok (data = " . $message->data . ")");

1;