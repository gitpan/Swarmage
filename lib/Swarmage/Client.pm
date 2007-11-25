# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/Client.pm 9635 2007-11-20T09:51:57.444029Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Client;
use strict;
use warnings;
use List::Util;
use UNIVERSAL::isa;
use UNIVERSAL::require;
use Swarmage::Component;
our @ISA = qw(Swarmage::Component);
use constant DEBUG => 0;

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
    my $start = time() if DEBUG;
    foreach my $q ( List::Util::shuffle( @{ $self->queues } ) ) {
        foreach my $task_class (@task_class) {
            my $task = eval { $q->fetch( queue => $task_class ) };
            if ($@) {
                print STDERR "Failed to fetch from queue: $task_class: $@\n";
            }
            if ($task) {
                push @tasks, $task;
            }
        }
    }
    if (DEBUG) {
        print STDERR ref($self) || $self, "->find_task(): ", scalar(@tasks), " fetched in ", time() - $start, " seconds\n";
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