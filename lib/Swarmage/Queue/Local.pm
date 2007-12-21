# $Id: /mirror/perl/Swarmage/branches/2.0-redo/lib/Swarmage/Queue/Local.pm 36146 2007-12-21T01:16:22.381058Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Queue::Local;
use strict;
use warnings;
use base qw(Swarmage::Queue::DBI);

__PACKAGE__->table_name('local_queue');
__PACKAGE__->mk_accessors($_) for qw(filename cleanup);

sub new
{
    my $class = shift;
    my %args  = @_;
    my $filename = $args{filename} || "local_queue-$$.db";
    my $cleanup  = exists $args{cleanup} ? $args{cleanup} : 1;

    my $self = $class->SUPER::new(
        connect_info => [
            "dbi:SQLite:dbname=$filename",
            undef,
            undef,
            { RaiseError => 1, AutoCommit => 1 }
        ]
    );
    $self->filename( $filename );
    $self->cleanup( $cleanup );
    return $self;
}

sub prepare_db
{
    my $self = shift;

    $self->SUPER::prepare_db();

    my $dbh   = $self->dbh;
    my $table = $self->table_name;
    eval { 
        my $sth = $dbh->prepare("SELECT 1 FROM $table");
        $sth->execute();
        $sth->finish();
    };
    if (my $e = $@) {
        if ($e =~ /no such table/) {
            $dbh->do(<<"            EOSQL");
                CREATE TABLE IF NOT EXISTS $table (
                    id          TEXT PRIMARY KEY,
                    task_type   TEXT NOT NULL,
                    task_data   TEXT NOT NULL,
                    taken_by    TEXT,
                    taken_on    NUMERIC,
                    modified_on NUMERIC,
                    inserted_on NUMERIC NOT NULL
                );
            EOSQL
        } else {
            die $e;
        }
    }
}

sub DESTROY
{
    my $self = shift;
    if ($self->cleanup && $self->filename) {
        unlink $self->filename;
    }
}

1;

__END__

=head1 NAME

Swarmage::Queue::Local - Local Queue

=head1 METHODS

=head2 new

=head2 prepare_db

=cut
