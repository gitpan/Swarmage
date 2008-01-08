# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/Util.pm 38203 2008-01-08T09:38:45.588768Z daisuke  $
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

    Class::Inspector->loaded($pkg) or $pkg->require or die;
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
