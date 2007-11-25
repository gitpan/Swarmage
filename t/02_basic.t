use strict;
use Test::More (tests => 10);

BEGIN
{
    use_ok("Swarmage::Task");
}

{
    my $t = Swarmage::Message->new;
    ok($t);
    isa_ok($t, 'Swarmage::Message');
    can_ok($t, qw(type data destination postback source attr persistent));
    is($t->persistent, 1);
}

{
    my $t = Swarmage::Task->new;
    ok($t);
    isa_ok($t, 'Swarmage::Task');
    can_ok($t, qw(type data destination postback task_class source attr persistent));
    is($t->persistent, 1);

    $t = Swarmage::Task->new(persistent => 0);
    is($t->persistent, 0);
}



# XXX more to come...