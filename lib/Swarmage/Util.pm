# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/Util.pm 39562 2008-01-21T07:34:51.765326Z daisuke  $
#
# Copyright (c) 2007-2008 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved

package Swarmage::Util;
use strict;
use warnings;
use Carp qw(croak);
use Class::Inspector;
use UNIVERSAL::require;

sub load_module
{
    my $pkg    = shift;
    my $prefix = shift;

    croak "Received empty package name" if ! $pkg;
    unless ($pkg =~ s/^\+//) {
        $pkg = ($prefix ? "${prefix}::${pkg}" : $pkg);
    }

    if (! Class::Inspector->loaded($pkg) ){
        eval {
            $pkg->require or die;
        };
        warn if $@;
    }
    return $pkg;
}

1;

__END__

=head1 NAME

Swarmage::Util - Swarmage General Utilities

=head1 SYNOPSIS

  use Swarmage::Util;
  Swarmage::Util::load_module('My::Module', 'Prefix::Namespace');
  Swarmage::Util::load_module('+My::Module');

=head1 METHODS

=head2 load_module($module, $prefix)

Loads a module. If the module name starts with a '+', then the module name
is taken as-is without the '+'. Otherwise, the module name is prefixed with
the second argument $prefix

=cut
