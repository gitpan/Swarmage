# $Id: /mirror/perl/Swarmage/branches/2.0-redo/t/lib/SwarmageTest/Worker/Factorial.pm 36144 2007-12-21T01:05:54.525393Z daisuke  $

package SwarmageTest::Worker::Factorial;
use strict;
use warnings;
use Swarmage::Task;

sub new
{
    bless {}, shift;
}

my %correct = (
    1 => 1,
    2 => 2,
    3 => 6,
    4 => 24,
    5 => 120,
    6 => 720,
    7 => 5040,
    8 => 40160,
    9 => 361440,
);
sub work
{
    my ($self, $task) = @_;
    my $n = int($task->data);
    my $result = $self->factorial( $n, 1 );
#    Test::More::is($result, $correct{ $n }, "$n! is $correct{ $n } (was $result)");

    return Swarmage::Task->new(
        type => "local:hexadecimal",
        data => $result
    );
        
#    return $result;
}

sub factorial
{
    my ($self, $n, $sofar) = @_;

    if ($n > 0) {
        return $self->factorial( $n - 1, $n * $sofar);
    } else {
        return $sofar;
    }
}

1;