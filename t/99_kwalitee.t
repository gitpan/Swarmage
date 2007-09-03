use Test::More;
BEGIN
{
    if (! $ENV{TEST_KWALITEE}) {
        plan skip_all => "Enable TEST_KWALITEE environment variable to test Kwalitee";
    } else {
        eval "use Test::Kwalitee";
        plan skip_all => 'Test::Kwalitee required for testing kwalitee'  if $@;
    }
}
