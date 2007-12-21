# $Id: /mirror/perl/Swarmage/branches/2.0-redo/t/lib/SwarmageTest/Worker/Hexadecimal.pm 36144 2007-12-21T01:05:54.525393Z daisuke  $

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