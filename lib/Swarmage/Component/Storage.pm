# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/Component/Storage.pm 2425 2007-09-03T10:56:40.325353Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Component::Storage;
use strict;
use warnings;
use Swarmage::Component;
our @ISA = qw(Swarmage::Component);
use UNIVERSAL::require;
use List::Util ();

__PACKAGE__->mk_group_accessors(simple => qw(_storage_list storage_args));
__PACKAGE__->mk_classaccessor(default_storage_class => 'Stomp');

sub new
{
    my $class = shift;
    my $self  = $class->next::method(@_);
    my %args  = @_;

    $self->_storage_list([]);
    $self->storage_args($args{storage});
    $self->setup_storage();
    return $self;
}

sub setup_storage
{
    my $self = shift;
    my $config = $self->storage_args;
    if (ref $config ne 'ARRAY') {
        $config = [ $config ];
    }

    my $list = $self->storage_list;
    foreach my $h (@$config) {
        my $storage_class = delete $h->{class} || $self->default_storage_class;
        if ($storage_class !~ s/^\+//) {
            $storage_class = 'Swarmage::Storage::' . $storage_class;
        }
        $storage_class->require or die;

        my $storage = $storage_class->new(%$h);
        push @$list, $storage;
    }
}

sub storage_list
{
    my $self = shift;
    my %args = @_;
    my $list = $self->_storage_list;
    if (wantarray) {
        return $args{shuffled} ? List::Util::shuffle(@$list) : @$list;
    } else {
        return $list;
    }
}

1;


__END__

=head1 NAME

Swarmage::Component::Storage

=head1 METHODS

=head2 new

=head2 setup_storage

=head2 storage_list

=cut
