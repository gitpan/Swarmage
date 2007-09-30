package SwarmageTest::Worker::Sum;
use strict;
use base qw(Swarmage::Worker);

__PACKAGE__->abilities('sum');

sub work_once
{
    my ($self, $task) = @_;
    $self->is_running(0);
    return $task->data->{arg1} + $task->data->{arg2};
}

1;