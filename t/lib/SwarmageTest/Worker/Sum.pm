package SwarmageTest::Worker::Sum;
use strict;
use base qw(Swarmage::Worker);

sub new
{
    my $class = shift;
    $class->next::method(@_, 
        abilities => {
            'sum' => \&sum
        }
    );
}

sub sum
{
    my ($self, $task) = @_;
    my $time = int(rand(10));
    print STDERR "$$ sum ... sleep for $time ... ";
    select(undef, undef, undef, $time);
    print STDERR "done. result is ", $task->data->{arg1} + $task->data->{arg2}, "\n";
}

1;