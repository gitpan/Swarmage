# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/Queue/BerkeleyDB.pm 39735 2008-01-23T02:57:57.044329Z daisuke  $
#
# Copyright (c) 2007-2008 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Queue::BerkeleyDB;
use strict;
use warnings;
use base qw(Swarmage::Queue);
use BerkeleyDB;
use Carp qw(croak);
use Path::Class::Dir;
use Path::Class::File;

__PACKAGE__->mk_accessors($_) for qw(backend filename task_ids unlink);

sub new
{
    my $class = shift;
    my %args  = @_;
    my $filename = Path::Class::File->new( $args{filename} || "local_queue-$$.db" );

    # home/filename/filename
    my $home     = Path::Class::Dir->new( $filename->stringify )->absolute;
    if (! -d $home) {
        $home->mkpath or die;
    }

    my $env     = BerkeleyDB::Env->new(
        -Home     => $home->stringify,
        -Flags    => DB_CREATE | DB_INIT_MPOOL,
        -ErrFile  => 'error.log',
    ) or croak "Could not open BerkeleyDB::Env: $BerkeleyDB::Error";

    my $backend = BerkeleyDB::Hash->new(
        -Filename => $home->file( $filename->basename )->stringify,
        -Flags    => DB_CREATE, 
        -Property => DB_DUP,
        -Mode     => 0600,
        -Env      => $env,
    ) or croak "Could not create BerkeleyDB::Hash: $BerkeleyDB::Error";

    my $unlink = exists $args{unlink} ? $args{unlink} : 1;

    my $self = bless {
        backend    => $backend,
        filename   => $filename,
        unlink     => $unlink,
        task_ids   => {},
    }, $class;

    return $self;
}

sub enqueue
{
    my $self = shift;
    my $task = shift;

    my $backend = $self->backend;
    $backend->db_put( $task->type, $task->serialize_raw );
    $self->task_ids->{ $task->id }++;
}

sub dequeue
{
    my $self = shift;
    my $id   = shift;

    return unless $self->task_ids->{ $id };

    my $backend = $self->backend;
    my $cursor  = $backend->db_cursor();

    my ($k, $v) = ( '', '' );
    while ($cursor->c_get($k, $v, DB_NEXT) == 0) {
        my $task = Swarmage::Task->deserialize_raw($v);
        if ($task->id eq $id) {
            delete $self->task_ids->{ $id };
            $cursor->c_del();
            last;
        }
    }
    undef $cursor;
}

sub pump
{
    my $self       = shift;
    my %args       = @_;
    my $task_types = $args{task_types};
    my $limit      = $args{limit} || 10;

    my @tasks;
    my $backend = $self->backend;
    my $cursor = $backend->db_cursor();

    my %task_types = map { ($_ => 1) } @$task_types;
    my ($k, $v) = ('', '');
    my $count = 0;
    while ($cursor->c_get($k, $v, DB_NEXT) == 0) {
        my $task = Swarmage::Task->deserialize_raw($v);
        if ($task_types{ $task->type }) {
            push @tasks, $task;
            $count++;
            $self->task_ids->{ $task->id }--;
            delete $self->task_ids->{$task->id} unless $self->task_ids->{ $task->id };
            if ($cursor->c_del() != 0) {
                warn "Failed to delete from cursor: $BerkeleyDB::Error";
            }
            last if $limit <= $count;
        }
    }
    $backend->db_sync();
    undef $cursor;

    return @tasks;
}

sub DESTROY
{
    my $self = shift;

    $self->backend->db_close();
    if ($self->unlink) {
        $self->filename->parent->rmtree(0, 0);
    }
}

1;

__END__

=head1 NAME

Swarmage::Queue::BerkeleyDB - BerkeleyDB Based Queue

=head1 SYNOPSIS

  use Swarmage::Queue::BerkeleyDB;
  my $queue = Swarmage::Queue::BerkeleyDB->new(
    filename => "/path/to/db"
  );

=head1 METHODS

=head2 new

=head2 enqueue

=head2 dequeue

=head2 pump

=cut