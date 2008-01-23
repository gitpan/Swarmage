# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/Worker/Generic.pm 39721 2008-01-22T08:55:20.406505Z daisuke  $
#
# Copyright (c) 2007-2008 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Worker::Generic;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use POE;

use constant GENERIC_DEBUG => 0;
use constant GENERIC_VERBOSE => 1;

__PACKAGE__->mk_accessors($_) for qw(worker slave timeout session_id);

sub new
{
    my $class = shift;
    my %args  = @_;
    my $timeout = $args{timeout};

    my $self = bless {
        timeout => $timeout,
        worker  => delete $args{worker},
        args    => \%args, # fore re-spawn
    }, $class;

    my $session = POE::Session->create(
        inline_states => {
            _start => sub { },
        },
        object_states => [
            $self => {
                map { ($_ => "_poe_$_") }
                qw(set_timeout timeout_reached)
            }
        ]
    );
    $self->session_id($session->ID);
    $self->spawn_slave;
    return $self;
}

sub spawn_slave
{
    my $self = shift;
    my $slave = POE::Component::Generic->spawn(
        debug => GENERIC_DEBUG,
        verbose => GENERIC_VERBOSE,
        package => "Swarmage::Worker::Generic::Slave",
        object_options => [ %{ $self->{args} } ],
        methods        => [ qw(work) ]
    );
    if (my $old_slave = $self->slave) {
        $old_slave->shutdown();
    }
    $self->slave( $slave );
}

sub work
{
    my ($self, $ref, $task) = @_;

    # Set a timeout alarm, if we've been instructed to use it
    POE::Kernel->call($self->session_id, "set_timeout");

    # Now work
    $self->slave->work($ref, $task);
}

sub _poe_set_timeout
{
    my ($self, $kernel) = @_[OBJECT, KERNEL];
    if (my $timeout = $self->timeout) {
        $kernel->alarm_set( 'timeout_reached', $self->timeout )
    }
}

sub _poe_timeout_reached
{
    my $self = $_[OBJECT];

    $self->stop_slave();
}

sub stop_slave
{
    my $self = shift;
    $self->slave->{wheel}->kill();
    $self->spawn_slave();
}

package Swarmage::Worker::Generic::Slave;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors($_) for qw(slave);

sub new
{
    my $class = shift;
    my %args  = @_;

    my $slave_pkg = Swarmage::Util::load_module($args{module});
    my $slave     = $slave_pkg->new( %{ $args{config} || {} } );
    bless {
        slave => $slave
    }, $class;
}


sub work
{
    my ($self, $task) = @_;
    my @ret = eval { $self->slave->work( $task ) };
    warn if $@;
    return @ret;
}

1;

__END__

=head1 NAME

Swarmage::Worker::Generic - POE::Component::Generic Wrapper For Swarmage::Worker

=head1 METHODS

=head2 new

=head2 spawn_slave

=head2 stop_slave

=head2 work

=cut
