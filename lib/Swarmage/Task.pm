# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/Task.pm 38128 2008-01-07T04:52:02.712309Z daisuke  $
#
# Copyright (c) 2007-2008 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Task;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Digest::MD5 ();
use MIME::Base64 ();
use Storable ();

__PACKAGE__->mk_accessors($_) for qw(id type data postback prev);

sub new
{
    my $class = shift;
    my %args  = @_;
    my $self  = bless {
        id       => Digest::MD5::md5_hex($$, rand(), {}, time()),
        type     => $args{type},
        data     => $args{data},
        postback => $args{postback},
    }, $class;
    return $self;
}

*serialize = \&serialize_base64;
*deserialize = \&deserialize_base64;

sub serialize_base64
{
    my $self = shift;
    MIME::Base64::encode_base64( $self->serialize_raw );
}

sub deserialize_base64
{
    my $self = shift;
    $self->deserialize_raw( MIME::Base64::decode_base64( $_[0] ) );
}

sub serialize_raw
{
    my $self = shift;
    Storable::nfreeze( $self );
}

sub deserialize_raw
{
    my $self = shift;
    Storable::thaw( $_[0] );
}

1;

__END__

=head1 NAME

Swarmage::Task - A Task

=head1 SYNOPSIS

  use Swarmage::Task;
  Swarmage::Task->new(
    type => 'type',
    data => $whatever,
  );

=head1 METHODS

=head2 new

=head2 serialize

=head2 deserialize

=head2 serialize_raw

=head2 deserialize_raw

=head2 serialize_base64

=head2 deserialize_base64

=head2
