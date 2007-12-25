# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Worker::POE;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use POE;

__PACKAGE__->mk_accessors($_) for qw( slave );

sub new
{
    my $class = shift;
    my %args  = @_;

    my $slave_pkg = Swarmage::Util::load_module($args{module});
    my $slave     = $slave_pkg->new( %{ $args{config} || {} } );
    my $self      = $class->SUPER::new({ %args, slave => $slave });

    return $self;
}

sub work
{
    my ($self, $spec) = @_;

    my $task = Swarmage::Worker::POE::Task->new_from_task($spec->{task});

    my $session = $spec->{session};
    my $state   = $spec->{event};
    $task->register_event('done', sub {
        $poe_kernel->post( $session, $state, { %$spec, result => [@_] } )
            or die "Could not post to $state";
    } );

    my $slave = $self->slave;
    $poe_kernel->post( $slave->session_id, $slave->work_begin_event, $task )
        or die "Could not post to slave";
}

package Swarmage::Worker::POE::Task;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Event::Notify;

__PACKAGE__->mk_accessors($_) for qw(_task);

sub new_from_task
{
    my $class = shift;
    my $task  = shift;
    my $self = bless {
        _task  => $task,
        notify => Event::Notify->new()
    }, $class;
    $self;
}

BEGIN
{
    foreach my $method qw(id type data postback prev) {
        { no strict 'refs';
            *{$method} = sub { shift->_task->$method(@_) };
        }
    }
}

sub notify { 
    my $self = shift;
    if (! @_) {
        push @_, 'done';
    }
    $self->{notify}->notify(@_);
}
sub register_event { shift->{notify}->register_event(@_) }
sub unregister_event { shift->{notify}->unregister_event(@_) }

1;

__END__

=head1 NAME

Swarmage::Worker::POE - POE Based Worker Backend

=head1 SYNOPSIS

  use Swarmage;
  Swarmage::Drone->new(
    workers => [
      {
        module => '+MyWorker',
        backend => 'POE',
        config => { ... }
      }
    ]
  );

=head1 DESCRIPTION

This worker is intended for those tasks that can be done within the
same process as the main Swarmage session, using POE. It's really meant
to be a quick bridge betwen Swarmage and other POE-based applications,
such as Gungho.

Your slave object needs to be able to tell to which session / to which event
the task must be routed to. It is expected that your slave object implement
these two methos, which return their respective values:

  session          # the session ID / alias 
  work_begin_state # the name of the event that gets triggered

When you're done with your work, invoke the task's notify() method

  $task->notify();

If you have return values, you need to pass it to the notify() method:

  $task->notify($val1, \@val2, \%val3);

=head1 METHODS

=head2 new

=head2 work

=cut