# $Id$

package SwarmageTest::Task::Process;
use strict;
use warnings;
use base qw(Process);

sub new
{
    my $class = shift;
    my %args  = @_;
    return bless {
        number => $args{number}
    }, $class;
}

sub prepare {}
sub run
{
    my $self = shift;
    $self->{result} = $self->{number} * 10;
}

1;
