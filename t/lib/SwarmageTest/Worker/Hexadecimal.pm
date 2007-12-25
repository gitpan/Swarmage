# $Id: /mirror/perl/Swarmage/trunk/t/lib/SwarmageTest/Worker/Hexadecimal.pm 36876 2007-12-25T03:11:23.372766Z daisuke  $

package SwarmageTest::Worker::Hexadecimal;
use strict;
use warnings;

sub new
{
    bless {}, shift;
}

sub work
{
    my ($self, $task) = @_;
    my $n = int($task->data);
    my $result = sprintf('%x', $n);
    return $result;
}

1;