# $Id$
#
# Copyright (c)

package Swarmage::Queue::IKC;
use strict;
use warnings;
use POE qw(Component::IKC::Client);

sub new
{
    my $class = shift;
    my %args  = @_;

    my $name = $args{name};
    POE::Component::IKC::Client->spawn(
        %args,
    );

    my $session = POE::Session->create(
        object_states => [
            $self => {
                _start => '_poe_start',
                map { ($_ => "_poe_$_") } 
                    qw(ikc_remote_register ikc_remote_unregister ikc_remote_subscribe ikc_remote_unsubscribe)
            }
        ]
    );
    $self->session_id( $session->ID );
    return $self;
}

sub _poe_start
{
    my $kernel = $_[KERNEL];
    $kernel->post($name, 'monitor', '*', {
        map { ($_ => "ikc_remote_$_") } 
            qw(register unregister subscribe unsubscribe)
}

sub pump
{
    my $self       = shift;
    my %args       = @_;
    my $task_types = $args{task_types};
    my $limit      = $args{limit} || 10;

    POE::Kernel->post($self->ikc_name, 'pump', \%args);
}

sub _poe_got_task
{
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
  $queue->pump( event => "got_task" );

=head1 DESCRIPTION

Swarmage::Queue::IKC::Client attaches itself to a remote POE kernel, and
asks the remote kernel for new tasks to be executed.

The remote kernel must implement a "pump" state, which should accept

=cut