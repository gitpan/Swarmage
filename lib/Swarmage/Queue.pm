# $Id: /mirror/perl/Swarmage/branches/2.0-redo/lib/Swarmage/Queue.pm 36250 2007-12-24T09:03:47.335980Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Queue;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);

sub new {}
sub dequeue {}
sub enqueue {}
sub pump {}

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

=head2 dequeue

=head2 enqueue

=head2 poll_wait

=head2 pump

=cut
