# $Id: /mirror/perl/Swarmage/branches/2.0-redo/lib/Swarmage/Drone.pm 36144 2007-12-21T01:05:54.525393Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Drone;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use DBI;
use Log::Dispatch;
use Log::Dispatch::Handle;
use IO::Handle;
use POE ;
use Swarmage::Queue::Local;
use Swarmage::Task;
use Swarmage::Util;
use Swarmage::Worker;

__PACKAGE__->mk_accessors($_) for qw(config alias delay log queue local_queue workers max_tasks buffered_tasks task_types);

sub new
{
    my $class = shift;
    my %args  = @_;

    my $alias = $args{alias} || do {
        require Sys::Hostname;
        join('-', Sys::Hostname::hostname(), $$, rand())
    } || die;

    my $self = bless {
        config         => \%args,
        alias          => $alias,
        workers        => [],
        max_tasks      => {},
        buffered_tasks => {},
        task_types     => {},
        delay          => 1,
    }, $class;
    $self->setup_log();

    POE::Session->create(
        heap => {
            shutdown => 0,
        },
        object_states => [
            $self, {
                _start => '_poe_start',
                map { ($_ => "_poe_$_") } qw(
                    spawn_queue
                    pump_queue
                    pump_worker_queue
                    buffer_work
                    monitor
                )
            }
        ]
    );

}

sub setup_log
{
    my $self = shift;
    my $log = Log::Dispatch->new(
        callbacks => sub {
            my %args = @_;
            my $message = $args{message};
            $message =~ s/(?!\n)\Z/\n/;
            $message = "[$args{level}]: $message";
            return $message;
        }
    );
    my $stderr = Log::Dispatch::Handle->new(
        name      => 'stderr',
        min_level => 'debug',
        handle    => do {
            my $io = IO::Handle->new;
            $io->fdopen(fileno(STDERR), "w");
            $io;
        }
    );
    $log->add( $stderr );
    $self->log( $log );
}

sub _poe_start
{
    my ($self, $kernel, $session) = @_[OBJECT, KERNEL, SESSION, ARG0];
    if (my $alias = $self->alias) {
        $self->log->debug("Setting alias '$alias'");
        $kernel->alias_set($alias);
    }

    # Create a local queue
    my $local_queue = Swarmage::Queue::Local->new();
    $self->local_queue( $local_queue );

    # Create external queue
    my $extern_queue = $kernel->call($session, 'spawn_queue', $self->config->{queue}) or die;
    $self->queue( $extern_queue );

    my @task_types;
    while (my ($task_type, $config) = each %{ $self->config->{workers} }) {
        if (ref $config ne 'ARRAY') {
            $config = [ $config ];
        }

        foreach my $conf (@$config) {
            $self->register_worker( $task_type, $conf );
        }
        push @task_types, $task_type;
    }
    $kernel->yield('monitor');
}

sub register_worker
{
    my ($self, $task_type, $config) = @_;

    # XXX - Fix calling syntax for task_type
    my $worker = Swarmage::Worker->new(
        %$config,
        task_type => $task_type,
        filename => $self->local_queue->filename,
        parent => $self
    );
    push @{$self->workers}, $worker;

    $self->task_types->{ $worker->task_type } ||= [];
    push @{ $self->task_types->{ $worker->task_type } }, $worker;

    # The Drone can poll up to N number of jobs per worker. 
    # each worker is responsible for 1 task type, so we don't need to poll
    # task types for which the worker has been saturated.
    # To ease that process, we calculate the number of max jobs per
    # task here

    my $max_per_worker = 15;
    $self->max_tasks->{ $worker->task_type } ||= 0;
    $self->max_tasks->{ $worker->task_type } += 15;


    $worker->register_event('work_done', $self, { method => 'mark_worker_done' });
}

sub mark_worker_done
{
    my ($self, $event, $task) = @_;
    $self->buffered_tasks->{ $task->type }--;

    $self->queue->dequeue( $task->id );

    # If a worker is reported to be done, then there should be an empty
    # slot in the worker pool. pump the workers!

    if (! $self->{worker_pump_pending}{ $task->type }++) {
        $poe_kernel->yield('pump_worker_queue', $task->type);
    }
}

sub _poe_pump_worker_queue
{
    my ($self, $kernel, $task_type) = @_[ OBJECT, KERNEL, ARG0 ];

    delete $self->{worker_pump_pending}{ $task_type };

    my $workers = $self->task_types->{ $task_type };
    foreach my $worker (@$workers) {
        $poe_kernel->post($worker->session_id, 'pump_queue') or die;
    }
}

sub postback
{
    my $self = shift;
    $self->queue->enqueue($_[0]);
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

    delete $heap->{pump_pending};
    my $buffered_tasks = $self->buffered_tasks;
    my $max_tasks = $self->max_tasks;
    foreach my $task_type (keys %{ $max_tasks }) {
        my $diff = $max_tasks->{$task_type} - ($buffered_tasks->{$task_type} || 0);
        if ($diff > 0) {
            $self->log->debug("PUMP: $task_type");
            $self->queue->pump(
                event      => 'buffer_work',
                task_types => [ $task_type ],
                limit      => $diff,
            );
        }
    }
}

sub _poe_buffer_work
{
    my ($self, $kernel, $heap, $ref) = @_[OBJECT, KERNEL, HEAP, ARG0];

    my %task_types;
    foreach my $task (@{ $ref->{result} || [] }) {
warn "buffered task $task";
        $self->buffered_tasks->{$task->type}++;
        $self->local_queue->enqueue($task);
        $task_types{ $task->type }++;
    }

    # Grrrrr, this is so inefficient
    foreach my $task_type (keys %task_types) {
        foreach my $worker (@{ $self->workers }) {
            next unless $worker->task_type eq $task_type;
            $kernel->post($worker->session_id, 'pump_queue') or die;
        }
    }
}

sub _poe_spawn_queue
{
    my ($self, $kernel, $session, $heap, $config) = @_[OBJECT, KERNEL, SESSION, HEAP, ARG0];
    my $queue_pkg = Swarmage::Util::load_module(
        $config->{module} || 'DBI::Generic',
        'Swarmage::Queue'
    );

    $self->log->debug("Setting up queue $queue_pkg");
    my $queue = $queue_pkg->new(
        %{ $config->{config} || {} },
        log => $self->log,
    );
}

1;

__END__

=head1 NAME

Swarmage::Drone - The Drone

=head1 SYNOPSIS

  use Swarmage::Drone;
  Swarmage::Drone->new(
    queues => [
      {
        module => 'DBI::Generic',
        config => {
          connect_info => [
            'dbi:Pg:dbname=swarmage',
            $username,
            $password,
            ...
          ],
          taks_types   => [ qw(foo bar) ],
        },
      }
    ],
    workers => {
        foo => {
            module => '+MyWorker',
            config => {
                ....
            }
        },
        # multiple workers
        bar => [
            {
                module => '+MyWorker2',
                config => {
                    ...
                }
            },
            {
                module => '+MyWorker2',
                config => {
                    ...
                }
            },
        ]
    }
  );
  POE::Kernel->run();

=head1 DESCRIPTION

The Drone is responsible for retrieving jobs from the system queue, then 
launching, and keeping track of workers.  It's assumed that a Drone may contain multiple types of Workers, and that these Workers coordinate with each other,
thus forming a small cluster of processes that implement a particular logic set.

The Drone uses two sets of queues. One is the Global Queue, which is the queue
that is shared amongst Drones. The other is the Local Queue, which is shared
between one Drone and one or more Workers belonging to that Drone.

The Global Queue may be implemented in terms of a database, a message queue, 
or whatever that handles its own non-blocking logic to check for incoming tasks.
The Local Queue is implemeted with a simple SQLite database.

When an incoming task is notified by the Queue, the Drone checks the job's
type, and dispatches to the appropriate Worker.

=head1 METHODS

=head2 new

=head2 postback

=head2 register_worker

=head2 mark_worker_done

=head2 setup_log

=cut
