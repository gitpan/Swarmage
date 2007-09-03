# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/CLI/Help.pm 2425 2007-09-03T10:56:40.325353Z daisuke  $
# 
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::CLI::Help;
use strict;
use warnings;
use App::CLI::Command;
our @ISA = qw(App::CLI::Comand);

sub run
{
    print <<EOHELP;
swarmage [command] 
EOHELP
}

1;


__END__

=head1 NAME

Swarmage::CLI::Help

=head1 METHODS

=head2 run

=cut
