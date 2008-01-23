# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/Worker.pm 39737 2008-01-23T04:05:41.075018Z daisuke  $
#
# Copyright (c) 2007-2008 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Worker;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Event::Notify;
use POE qw(Component::Generic);
use Swarmage::Queue::Local;
use UNIVERSAL::require;

__PACKAGE__->mk_accessors($_) for qw( queue task_type backend session_id parent delay log );

sub new
{
    my $class = shift;
    my %args  = @_;

    my $queue    = delete $args{queue} ||
        Swarmage::Queue::Local->new()
    ;

    my $parent    = delete $args{parent} || die;
    my $task_type = delete $args{task_type};
    my $delay     = delete $args{delay} || 30;
    my $backend   = delete $args{backend} ||
        'Swarmage::Worker::Generic';
    
    my $self  = bless {
        queue      => $queue,
        task_type  => $task_type,
        backend    => $backend,
        parent     => $parent,
        delay      => $delay,
        log        => $parent->log,
        notify_hub => Event::Notify->new,
    }, $class;

    $backend = ref $backend ? $backend : 
        do {
            $backend = Swarmage::Util::load_module($backend);
            $backend->new(%args, worker => $self);
        }
        or die $@
    ;
        
    $self->backend($backend);

    my $session = POE::Session->create(
        object_states => [
            $self, {
                _start => '_poe_start',
                map { ($_ => "_poe_$_") } qw(
                    work_begin
                    work_done
                    pump_queue
                    monitor
                )
            }
        ]
    );
    $self->session_id( $session->ID );
    return $self;
}

sub notify           { shift->{notify_hub}->notify(@_) }
sub register_event   { shift->{notify_hub}->register_event(@_) }
sub unregister_event { shift->{notify_hub}->unregister_event(@_) }

sub _poe_start
{
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    $kernel->yield('monitor');
}

sub _poe_monitor
{
    my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];

    if (! $heap->{pump_pending}) {
        $heap->{pump_pending} = $kernel->delay_set('pump_queue', 1);
    }
    $kernel->delay_set('monitor', $self->delay);
}

sub _poe_pump_queue
{
    my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];

    my $queue = $self->queue;
    $kernel->alarm_remove( $heap->{pump_pending} );

    delete $heap->{pump_pending};

    my @tasks = $queue->pump(
        session    => $self->session_id,
        event      => 'work_begin',
        task_types => [ $self->task_type ],
        limit      => 1
    );
    $kernel->yield('work_begin', \@tasks);
}

sub _poe_work_begin
{
    my ($self, $kernel, $heap, $tasks) = @_[OBJECT, KERNEL, HEAP, ARG0];

    delete $heap->{pump_pending};

    my @tasks = @{$tasks};
    # If we didn't receive any tasks, re-dispatch a fetch request
    # in X amount of time, which will grow as we encounter more
    # empty queues

    $self->log->debug("[WORKER]: PUMPED " . scalar(@tasks) . " tasks");

    if (! @tasks ) {
        $heap->{pump_pending} = $kernel->delay_set('pump_queue', $self->delay);
    } else {
        $self->backend->work( {
            wantarray => 1,
            session => $self->session_id,
            event   => 'work_done',
            task    => $tasks[0]
        }, $tasks[0]);
    }
}

sub _poe_work_done
{
    my ($self, $kernel, $ref) = @_[OBJECT, KERNEL, ARG0];

    $self->log->debug("[WORKER]: DONE");
    my $result = $ref->{result} || [];
    my $task = $ref->{task};

    my $chained = 0;
    if (scalar @$result == 1 && eval { $result->[0]->isa('Swarmage::Task') }) {
        my $new_task = $result->[0];
        my $type = $new_task->type;
        if ($type =~ s/^local://) {
            $self->log->debug("[WORKER]: CHAIN");
            $new_task->type($type);
            # If the result is a single task, and its type starts with a 
            # "local:", then we pass this on to the local queue. This means 
            # that the job is actually "unfinished", and it must be processed 
            # by another worker in this cluster

            # If this happens, we need to chain the tasks, so that we
            # know exactly where this task came from
            $new_task->prev( $task );
            $self->queue->enqueue($new_task);
            $chained = 1;

            $kernel->post( $self->parent->alias, "pump_worker_queue", $type );
        }
    }

    # Make sure this task is delete from the local queue, and that the
    # result is properly propagated to the waiting client
    # But only if this request is at the end of the chain
    if (! $chained) {
        my $prev;
        my $current  = $task;
        my $local_queue = $self->queue;
        
        while ($prev = $current->prev) {
            $local_queue->dequeue( $prev );
            $current = $prev;
        }
        if (my $postback = $current->postback) {
            $self->log->debug("[WORKER]: POSTBACK");
            $self->parent->postback(
                Swarmage::Task->new(
                    type => $postback,
                    data => $ref->{result},
                )
            );
        }

        $self->notify( 'work_done', $current );
        $kernel->yield('pump_queue');
    }
}

1;

__END__

=head1 NAME

Swarmage::Worker - Swarmage Worker

=head1 SYNOPSIS

  # Internal use only
  my $worker = Swarmage::Worker->new(

=head1 DESCRIPTION

A Worker is a wrapper for your actual worker logic. It uses 
Swarmage::Worker::Generic or other backend modules as an adaptor to talk to 
your module.

=head1 METHODS

=head2 new

=head2 notify

=head2 register_event

=head2 unregister_event

=cut
