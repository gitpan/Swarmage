# $Id: /mirror/perl/Swarmage/branches/2.0-redo/lib/Swarmage/Queue/DBI.pm 36144 2007-12-21T01:05:54.525393Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All right reserved.

package Swarmage::Queue::DBI;
use strict;
use warnings;
use base qw(Class::Accessor::Fast Class::Data::Inheritable);
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
warn "Connecting to " . $self->connect_info->[0];
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

sub poll_wait
{
    my $self = shift;
    my %args = @_;

    my @tasks;
    while (! @tasks) {
        @tasks = $self->pump(%args);
        select(undef, undef, undef, rand(1));
    }
    return @tasks;
}

sub pump
{
    my $self       = shift;
    my %args       = @_;
    my $task_types = $args{task_types};

# warn "polling for @$task_types";

    my $where  = sprintf(
        'taken_by is NULL AND task_type IN (%s)',
        join(', ', ('?') x scalar(@$task_types))
    );
    my $limit = $args{limit} || 10;
    my $dbh = $self->dbh;

    my $table = $self->table_name;
    my $select_sth = $dbh->prepare(<<"    EOSQL");
        SELECT id, task_data, modified_on
        FROM $table
        WHERE $where
        ORDER BY inserted_on ASC
        LIMIT $limit
    EOSQL
    my $update_sth = $dbh->prepare_cached(<<"    EOSQL");
        UPDATE $table
        SET taken_by = ?,
            taken_on = ?,
            modified_on = ?
        WHERE
            id = ? AND modified_on = ?
    EOSQL

    my @tasks;
    $select_sth->execute(@$task_types);

    my ($id, $task_data, $modified_on);
    $select_sth->bind_columns(\($id, $task_data, $modified_on));
    while ($select_sth->fetchrow_arrayref) {
        my $now = Time::HiRes::time();
        if ($update_sth->execute($$, $now, $now, $id, $modified_on) > 0) {
            my $task = Swarmage::Task->deserialize($task_data);
            push @tasks, $task if $task;
        }
    }
    $select_sth->finish;
    $update_sth->finish;

# warn "$self Polling resulted in " . scalar(@tasks) . " tasks";

    return @tasks;
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
