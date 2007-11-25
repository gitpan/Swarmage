# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/Component.pm 9170 2007-11-14T14:35:16.376408Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Component;
use strict;
use warnings;
use Class::C3::Componentised;
use Class::Accessor::Grouped;
our @ISA = qw(Class::C3::Componentised Class::Accessor::Grouped);

sub component_base_class { __PACKAGE__ }

sub mk_accessors
{
    my $class = shift;
    $class->mk_group_accessor(simple => @_);
}

sub mk_classaccessor
{
    my $self = shift;
    $self->mk_group_accessors('inherited', $_[0]);
    $self->set_inherited(@_) if @_ > 1;
}

sub new
{
    my $class = shift;
    return bless { @_ }, $class;
}

1;

__END__

=head1 NAME

Swarmage::Component - Swarmage Component Base Class

=head1 DESCRIPTION

This is base class for Swarmage components. It automatically enables
Class::C3::Componentised and Class::Accessor::Grouped for you.

=head1 METHODS

=head2 new

Base constructor. Does not initialization (XXX - Probably should be changed)

=head2 mk_accessors

Creates a new instance accessor

=head2 mk_classaccessor

Creates a new class accessor

=head2 component_base_class

For Class::C3::Componentised

=cut
