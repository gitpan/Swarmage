package SwarmageTest::Schema::SwarmageTask;
use strict;
use warnings;
use DBIx::Class;
our @ISA = qw(DBIx::Class);

__PACKAGE__->load_components(qw(Core));
__PACKAGE__->table('swarmage_task');
__PACKAGE__->add_columns(
    "task_id",
    {
        data_type => "bigint",
        default_value => "nextval('swarmage_task_id_seq'::regclass)",
        is_nullable => 0,
        size => 8,
    },
    "task_class",
    {
        data_type => "text",
        default_value => undef,
        is_nullable => 0,
        size => 8,
    },
);

1;