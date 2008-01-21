# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/Queue/IKC/Client.pm 39063 2008-01-16T23:52:40.097783Z daisuke  $
#
# Copyright (c) 2007-2008 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Queue::IKC::Client;
use strict;
use warnings;
use base qw(Swarmage::Queue);
use POE qw(Component::IKC::Client);

__PACKAGE__->mk_accessors($_) for 
    qw(alias session_id remote_kernel ready remote_ip remote_port local_kernel log parent_session);

BEGIN
{
    if ($ENV{IKC_DEBUG}) {
        no warnings 'redefine';
        *POE::Component::IKC::Responder::DEBUG = sub { 1 };
        *POE::Component::IKC::Responder::Object::DEBUG = sub { 1 };
    }
}

sub is_async { 1 }

sub new
{
    my $class = shift;
    my %args  = @_;

    my $self = bless {
        remote_kernel  => '*',
        remote_ip      => $args{remote_ip} || '127.0.0.1',
        remote_port    => $args{remote_port},
        local_kernel   => $args{local_kernel} || "$class-$$",
        log            => $args{log},
        parent_session => POE::Kernel->get_active_session(),
        alias          => join('_', split(/::/, $class), $$),
    }, $class;
    $self->_create_ikc_client();
    return $self;
}

sub _session_start_callback
{
    my $self = shift;
    return sub { 
        my %states = (
            map { ($_ => "_poe_$_") } 
                qw(monitor got_task ikc_init ikc_remote_register ikc_remote_unregister ikc_remote_subscribe ikc_remote_unsubscribe ikc_connect)
        );
        my $session = POE::Session->create(
            object_states => [
                $self => {
                    _start => '_poe_start',
                    %states,
                }
            ]
        );
        $self->session_id( $session->ID );
    }
}

sub _poe_start
{
    my ($self, $kernel) = @_[OBJECT, KERNEL];
    $kernel->alias_set( $self->alias );
    $kernel->yield('ikc_init');
}

sub _poe_ikc_connect
{
    my $self = $_[OBJECT];
    $self->_create_ikc_client
}

sub _create_ikc_client
{
    my $self = shift;
    my @args = (
        ip         => $self->remote_ip,
        port       => $self->remote_port,
        name       => $self->alias,
        on_connect => $self->_session_start_callback()
    );
    create_ikc_client(@args);
}

sub _poe_ikc_init
{
    my ($self, $kernel) = @_[ OBJECT, KERNEL ];
    $kernel->call('IKC', 'monitor', '*',
        {
            map { ($_ => "ikc_remote_$_") } 
                qw(register unregister subscribe unsubscribe)
        }
    );
    $kernel->call('IKC', 'subscribe', sprintf('poe://%s/queue', $self->remote_kernel));
    $kernel->call('IKC', 'publish', $self->alias, [ qw(got_task) ]);
    $kernel->delay_set('monitor', 1800);
}

sub _poe_monitor
{
    $_[KERNEL]->delay_set('monitor', 1800);
}

sub enqueue
{
    my $self = shift;
    $poe_kernel->post( 'IKC', 'post', 
        sprintf('poe://%s/enqueue', $self->remote_kernel, $_[0]),
    );
}

sub dequeue
{
    my $self = shift;
    $poe_kernel->post( 'IKC', 'post', $self->remote_kernel, $_[0]);
}

# XXX - ARGH! Bad news. "event" doesn't quite work like other queues. 
# See poe_got_task.
sub pump
{
    my $self       = shift;
    my %args       = @_;
    my $event      = $args{event};
    my $task_types = $args{task_types};
    my $limit      = $args{limit} || 10;

    if (! $self->ready) {
        $self->log->debug("IKC Queue not ready yet (unconnected or unsubscribed)");
        return;
    }

    my $session = POE::Kernel->ID_id_to_session( $self->session_id );
    my $heap    = $session->get_heap();
    $heap->{work_respond_event}   ||= $event;
    POE::Kernel->post('IKC', 'call',
        sprintf('poe://%s/queue/pump', $self->remote_kernel),
        \%args,
        join('/', 'poe:', $self->alias, 'got_task'),
    );
}

sub _poe_got_task
{
    my ($self, $kernel, $heap, $tasks) = @_[OBJECT, KERNEL, HEAP, ARG0];

    if (! $tasks) {
        return;
    }

    # XXX - This is a hack. It sucks badly because we don't know where
    # the original pump() request came from. We just accept the fact that
    # this doesn't change for a particular session
    $kernel->call(
        $self->parent_session,
        $heap->{work_respond_event},
        { result => $tasks }
    );
    die "Couldn't send to requesting session " . $self->parent_session->ID . "/$heap->{work_respond_event}" if $!;
}

sub _poe_ikc_remote_register { }
sub _poe_ikc_remote_unregister
{
    my $is_unique = $_[ARG2];   
    if ($is_unique) {
        # We've been unregistered. We need to register back
        $_[OBJECT]->ready(0);
        $_[KERNEL]->yield('ikc_connect');
    }
}

sub _poe_ikc_remote_subscribe
{ 
    my $is_unique = $_[ARG2];   
    if ($is_unique) {
        $_[OBJECT]->ready(1);
    }
}

sub _poe_ikc_remote_unsubscribe
{
    my $is_unique = $_[ARG2];   
    if ($is_unique) {
        $_[OBJECT]->ready(0);
        $_[KERNEL]->yield('ikc_subscribe');
    }
}

1;

__END__

=head1 NAME

Swarmage::Queue::IKC::Client - IKC Client Acting As Queue

=head1 SYNOPSIS

  use Swarmage::Queue::IKC::Client;
  my $queue = Swarmage::Queue::IKC::Client->new(
    ip   => "xxx.xxx.xxx.xxx",
    port => "xxxx"
  );
  $queue->pump( ... )

=head1 DESCRIPTION

Swarmage::Queue::IKC::Client attaches itself to a remote POE kernel, and
asks the remote kernel for new tasks to be executed.

The remote kernel must implement a "pump" state, which should accept the
same arguments as the other queues.

=head1 METHODS

=head2 new

=head2 is_async

=head2 pump

Delegates to the remote kernel's pump event.

=head2 enqueue

Delegates to the remote kernel's enqueue event.

=head2 dequeue

Delegates to the remote kernel's dequeue event.

=cut