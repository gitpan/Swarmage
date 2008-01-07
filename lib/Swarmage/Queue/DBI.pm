# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/Queue/DBI.pm 38128 2008-01-07T04:52:02.712309Z daisuke  $
#
# Copyright (c) 2007-2008 Daisuke Maki <daisuke@endeworks.jp>
# All right reserved.

package Swarmage::Queue::DBI;
use strict;
use warnings;
use base qw(Swarmage::Queue Class::Data::Inheritable);
use DBI;
use Time::HiRes();

__PACKAGE__->mk_accessors($_) for qw(connect_info dbh);
__PACKAGE__->mk_classdata(table_name => 'queues');

sub new
{
    my $class = shift;
    my %args  = @_;
    my $self  = bless { connect_info => $args{connect_info} }, $class;
    $self->prepare_db();
    return $self;
}

sub prepare_db
{
    my $self = shift;
# warn "Connecting to " . $self->connect_info->[0];
    my $dbh = DBI->connect(@{ $self->connect_info });
    $self->dbh( $dbh );
}

sub enqueue
{
    my $self = shift;
    my $task = shift;
    my $dbh  = $self->dbh;

    eval {
        my $table = $self->table_name;
# warn "$self enqueue $table";
        my $sth = $dbh->prepare(<<"        EOSQL");
            INSERT INTO $table
                (id, task_type, task_data, modified_on, inserted_on)
            VALUES
                (?, ?, ?, ?, ?)
        EOSQL
        my $rv = $sth->execute($task->id, $task->type, $task->serialize, Time::HiRes::time(), Time::HiRes::time());
        if (! $rv) {
            die "Could not insert task: $@";
        }
        $sth->finish;
    };
    warn if $@;
}

sub dequeue
{
    my $self = shift;
    my $id   = shift;
    my $dbh  = $self->dbh;

    my $table = $self->table_name;
    my $sth = $dbh->prepare_cached(<<"    EOSQL");
        DELETE FROM $table WHERE id = ?
    EOSQL
    $sth->execute($id);
    $sth->finish;
}

sub pump
{
    my $self       = shift;
    my %args       = @_;
    my $task_types = $args{task_types};
    my $limit      = $args{limit} || 10;

    my @tasks;
    eval {
        my $where  = sprintf(
            'taken_by is NULL AND task_type IN (%s)',
            join(', ', ('?') x scalar(@$task_types))
        );
        my $dbh = $self->dbh;

        my $table = $self->table_name;
        my $select_sth = $dbh->prepare(<<"        EOSQL");
            SELECT id, task_data, modified_on
            FROM $table
            WHERE $where
            ORDER BY inserted_on ASC
            LIMIT $limit
        EOSQL
        my $update_sth = $dbh->prepare_cached(<<"        EOSQL");
            UPDATE $table
            SET taken_by = ?,
                taken_on = ?,
                modified_on = ?
            WHERE
                id = ? AND modified_on = ?
        EOSQL

        if ( $dbh->{Driver}->{Name} =~ /^sqlite$/) {
            $self->_fetch_sqlite(\@tasks, $select_sth, $task_types, $update_sth);
        } else {
            $self->_fetch_other(\@tasks, $select_sth, $task_types, $update_sth);
        }
        $select_sth->finish;
        $update_sth->finish;
    };
# warn "$self Polling resulted in " . scalar(@tasks) . " tasks";

    return @tasks;
}

sub _fetch_sqlite
{
    my ($self, $tasks, $select_sth, $task_types, $update_sth) = @_;

    my @candidates;
    $select_sth->execute(@$task_types);

    my ($id, $task_data, $modified_on);
    $select_sth->bind_columns(\($id, $task_data, $modified_on));
    while ($select_sth->fetchrow_arrayref) {
        push @candidates, [ $id, $task_data, $modified_on ];
    }
    $select_sth->finish;

    foreach my $data (@candidates) {
        my $now = Time::HiRes::time();
        if ($update_sth->execute($$, $now, $now, $id, $modified_on) > 0) {
            my $task = Swarmage::Task->deserialize($task_data);
            push @$tasks, $task if $task;
        }
        $update_sth->finish;
    }
}

sub _fetch_other
{
    my ($self, $tasks, $select_sth, $task_types, $update_sth) = @_;

    $select_sth->execute(@$task_types);

    my ($id, $task_data, $modified_on);
    $select_sth->bind_columns(\($id, $task_data, $modified_on));
    while ($select_sth->fetchrow_arrayref) {
        my $now = Time::HiRes::time();
        if ($update_sth->execute($$, $now, $now, $id, $modified_on) > 0) {
            my $task = Swarmage::Task->deserialize($task_data);
            push @$tasks, $task if $task;
        }
    }
}

1;

__END__

=head1 NAME

Swarmage::Queue::DBI - DBI Based Queue For Swarmage

=head1 SYNOPSIS

  # To use from POE:
  use Swarmage::Queue::DBI;
  use Swarmage::Queue::DBI::Generic;

  my $queue = Swarmage::Queue::DBI::Generic->new(
    connect_info => [
      'dbi:Pg:dbname=swarmage',
      $username,
      $password,
      { RaiseError => 1, AutoCommit => 1 }
    ]
  );

=head1 METHODS

=head2 new

=head2 enqueue

=head2 dequeue

=head2 poll_wait

=head2 prepare_db

=head2 pump

=cut
