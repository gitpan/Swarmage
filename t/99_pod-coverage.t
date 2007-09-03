use strict;
use Test::More;

BEGIN
{
    if (! $ENV{TEST_POD}) {
        plan skip_all => "Enable TEST_POD environment variable to test POD";
    } else {
        eval "use Test::Pod::Coverage";
        plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;

        # Ignore CLI for now
        my @modules = grep { !/CLI/ } Test::Pod::Coverage::all_modules();

        plan tests => scalar @modules;
        Test::Pod::Coverage::pod_coverage_ok($_) for @modules;
    }
}
