# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

use strict;
use Test::More (skip_all => 'Maybe later...');

#use strict;
#use File::Temp;
#use Test::More (tests => 6);
#use DBI;
#use lib("t/lib");
#BEGIN
#{
#    use_ok("Swarmage::Storage::DBIC");
#}
#
#unlink "t/swarmage.db";
#my @connect_info = (
#    'dbi:SQLite:dbname=t/swarmage.db',
#    '',
#    '',
#    { RaiseError => 1, AutoCommit => 0 }
#);
#my $dbh  = DBI->connect( @connect_info );
#$dbh->do(<<EOSQL);
#    CREATE TABLE swarmage_task (
#        task_id    AUTO_INCREMENT PRIMARY KEY NOT NULL,
#        task_class TEXT NOT NULL
#    );
#EOSQL
#$dbh->commit;
#$dbh->disconnect;
#
#my $storage = Swarmage::Storage::DBIC->new(
#    schema_class => 'SwarmageTest::Schema',
#    connect_info => \@connect_info
#);
#ok($storage);
#isa_ok($storage, 'Swarmage::Storage::DBIC');
#ok($storage->hash_id);
#ok($storage->schema);
#
#my $task = $storage->find_task({}, 'NonExistent');
#ok(! $task);
