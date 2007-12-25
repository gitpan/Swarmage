use strict;
use Test::More (tests => 4);

BEGIN
{
    use_ok("Swarmage::Task");
}

{
    my $t = Swarmage::Task->new;
    ok($t);
    isa_ok($t, 'Swarmage::Task');
    can_ok($t, qw(id type data postback prev serialize deserialize));
}

# XXX more to come...