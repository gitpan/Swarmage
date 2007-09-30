# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/Client.pm 2909 2007-09-30T13:06:51.115468Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Client;
use strict;
use warnings;
use UNIVERSAL::isa;
use UNIVERSAL::require;
use Swarmage::Component;
our @ISA = qw(Swarmage::Component);
use List::Util;

__PACKAGE__->mk_group_accessors(simple => qw(queues));

sub new
{
    my $class = shift;
    my %args  = @_;
    my $self  = $class->next::method(@_);

    $self->setup_queues($args{queues});
    return $self;
}

sub setup_queues
{
    my $self = shift;
    my $config = shift;
    if (ref $config ne 'ARRAY') {
        $config = [ $config ];
    }

    my $list = [];
    foreach my $h (@$config) {
        my $storage_class = delete $h->{class} || 'Stomp';
        if ($storage_class !~ s/^\+//) {
            $storage_class = 'Swarmage::Queue::' . $storage_class;
        }
        $storage_class->require or die;

        my $storage = $storage_class->new(%$h);
        push @$list, $storage;
    }
    $self->queues($list);
}

sub insert_task
{
    my ($self, $task) = @_;
    if ( ! $task->isa('Swarmage::Task')) {
        $task = Swarmage::Task->new(%$task);
    }

    foreach my $q ( List::Util::shuffle( @{ $self->queues } ) ) {
        return 1 if $q->insert( message => $task );
    }
    return ();
}

sub find_task
{
    my ($self, @task_class) = @_;

    my @tasks ;
    foreach my $q ( List::Util::shuffle( @{ $self->queues } ) ) {
        foreach my $task_class (@task_class) {
            my $task = $q->fetch( queue => $task_class );
            if ($task) {
                push @tasks, $task;
            }
        }
    }
    return wantarray ? @tasks : \@tasks;
}

1;

__END__

=head1 NAME

Swarmage::Client - Swarmage Client 

=head1 METHODS

=head2 new

=head2 setup_queues

=head2 insert_task

=head2 find_task

=cut