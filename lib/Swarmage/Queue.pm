# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/Queue.pm 38204 2008-01-08T09:40:38.051560Z daisuke  $
#
# Copyright (c) 2007-2008 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Queue;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);

sub new     {}
sub dequeue { die $_[0] . "::dequeue not implemented" }
sub enqueue { die $_[0] . "::enqueue not implemented" }
sub pump    { die $_[0] . "::pump not implemented" }
sub is_async { 0 }

sub poll_wait
{
    my $self = shift;
    my %args = @_;

    my @tasks;
    while (! @tasks) {
        @tasks = $self->pump(%args);
        select(undef, undef, undef, rand(1));
    }
    return @tasks;
}

1;

__END__

=head1 NAME

Swarmage::Queue - Base Class For Swarmage Queues

=head1 METHODS

=head2 new

=head2 is_async

Class method. Should return true if this queue implementation doesn't need to 
be wrapped up in Swarmage::Queue::Generic.

=head2 dequeue

=head2 enqueue

=head2 poll_wait

=head2 pump

=cut
