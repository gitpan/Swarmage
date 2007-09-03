package SwarmageTest::Schema;
use strict;
use DBIx::Class::Schema;
our @ISA = qw(DBIx::Class::Schema);

__PACKAGE__->load_classes(qw(SwarmageTask));

1;