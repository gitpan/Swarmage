# $Id: /mirror/perl/Swarmage/branches/2.0-redo/lib/Swarmage/Task.pm 36144 2007-12-21T01:05:54.525393Z daisuke  $
#
# Copyright (c) 207 Daisuke Maki <daisuke@endeworks.jp>
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

sub serialize
{
    my $self = shift;
    MIME::Base64::encode_base64( Storable::nfreeze( $self ) );
}

sub deserialize
{
    my $self = shift;
    Storable::thaw( MIME::Base64::decode_base64( $_[0] ) );
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

=head2
