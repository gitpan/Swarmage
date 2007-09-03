# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/CLI.pm 2425 2007-09-03T10:56:40.325353Z daisuke  $
# 
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::CLI;
use strict;
use warnings;
use App::CLI;
our @ISA = qw(App::CLI);

sub error_cmd
{
    print STDERR <<EOM;
$0 [command] [options]

swarmage worker Package::Name
EOM
    exit 1;
}

1;

__END__

=head1 NAME

Swarmage::CLI

=head1 METHODS

=head2 error_cmd

=cut