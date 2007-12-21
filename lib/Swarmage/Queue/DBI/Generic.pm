# $Id: /mirror/perl/Swarmage/branches/2.0-redo/lib/Swarmage/Queue/DBI/Generic.pm 36144 2007-12-21T01:05:54.525393Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Queue::DBI::Generic;
use strict;
use warnings;
use base qw(Class::Accessor::Fast Class::Data::Inheritable);
use Time::HiRes ();
use POE::Component::Generic;

__PACKAGE__->mk_accessors($_) for qw(backend parent);
__PACKAGE__->mk_classdata('backend_class' => 'Swarmage::Queue::DBI');

sub new
{
    my $class   = shift;
    my %args    = @_;
    my $backend = POE::Component::Generic->spawn(
        verbose => 1,
        package        => $class->backend_class,
        object_options => [ connect_info => $args{connect_info} ],
        methods        => [ qw(dequeue enqueue pump poll_wait) ]
    );

    my $self  = bless {
        parent   => $args{parent},
        backend  => $backend
    }, $class;
    return $self;
}

sub enqueue
{
    my $self = shift;
    my $task = shift;

    $self->backend->enqueue({}, $task);
}

sub dequeue
{
    my $self = shift;
    my $id   = shift;

    $self->backend->dequeue({}, $id);
}

sub pump
{
    my $self = shift;
    my %args = @_;
    $self->backend->pump({
        wantarray => 1,
        session   => delete $args{session},
        event     => delete $args{event}
    }, %args);
}

1;

__END__

=head1 NAME

Swarmage::Queue::DBI::Generic - POE::Component::Generic Wrapper For Swarmage::Queue::DBI

=head1 METHODS

=head2 new

=head2 enqueue

=head2 dequeue

=head2 pump

=cut
