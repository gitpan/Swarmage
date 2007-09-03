# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/Task.pm 2425 2007-09-03T10:56:40.325353Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Task;
use strict;
use warnings;
use Swarmage::Message;
our @ISA = qw(Swarmage::Message);

__PACKAGE__->mk_group_accessors(simple => qw(task_class source attr));

sub new
{
    my $class = shift;
    my %args = @_;
    my $self = $class->next::method(attr => {}, @_, type => 'task');

    foreach my $arg qw(task_class) {
        $self->$arg( $args{ $arg } );
    }
    if (! $self->destination) {
        $self->destination("task/" . $self->task_class);
    }
    return $self;
}

1;

__END__

=head1 NAME

Swarmage::Task

=head1 METHODS

=head2 new

=cut
