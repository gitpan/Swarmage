# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/Queue/Generic.pm 36876 2007-12-25T03:11:23.372766Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Queue::Generic;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use POE qw(Component::Generic);

__PACKAGE__->mk_accessors($_) for qw(backend backend_class parent log);
    

sub new
{
    my $class         = shift;
    my %args          = @_;
    my $verbose       = delete $args{verbose};
    my $parent        = delete $args{parent};
    my $backend_class = delete $args{class}  || die;
    my $log           = delete $args{log};
    my $backend = POE::Component::Generic->spawn(
        verbose        => $verbose,
        package        => $backend_class,
        object_options => [ %args ],
        methods        => [ qw(dequeue enqueue pump poll_wait) ]
    );

    my $self  = bless {
        parent   => $parent,
        backend  => $backend,
        log      => $log,
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

Swarmage::Queue::Generic - POE::Component::Generic Wrapper For Swarmage::Queue

=head1 SYNOPSIS

  use Swarmage::Queue::Generic;
  use Swarmage::Queue::BerkeleyDB;

  my $queue = Swarmage::Queue::Generic->new(
    class => "Swarmage::Queue::BerkeleyDB",
  );

=head1 METHODS

=head2 new

=head2 enqueue

=head2 dequeue

=head2 pump

=cut
