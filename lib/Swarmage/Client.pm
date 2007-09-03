# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/Client.pm 2425 2007-09-03T10:56:40.325353Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Client;
use strict;
use warnings;
use UNIVERSAL::isa;
use Swarmage::Component;
our @ISA = qw(Swarmage::Component);

__PACKAGE__->load_components( qw(Storage) );

sub new
{
    my $class = shift;
    my %args  = @_;
    my $self  = $class->next::method(@_);

}

sub insert_task
{
    my ($self, $task) = @_;

    if ( ! $task->isa('Swarmage::Task')) {
        $task = Swarmage::Task->new(%$task);
    }

    $self->_insert_storage($task);
}

sub _insert_storage
{
    my ($self, $task) = @_;

    my @list = $self->storage_list(shuffled => 1);
    foreach my $storage (@list) {
        return 1 if $storage->insert_queue( $task );
    }
    return ();
}

sub find_task
{
    my ($self, @task_class) = @_;

    my @list = $self->storage_list(shuffled => 1);
    my @tasks ;
    foreach my $storage (@list) {
        foreach my $task_class (@task_class) {
            my $task = $storage->fetch_queue($task_class);
            if ($task) {
                $task->source($storage);
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

=head2 insert_task

=head2 find_task

=cut