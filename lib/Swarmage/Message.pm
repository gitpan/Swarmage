# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/Message.pm 9170 2007-11-14T14:35:16.376408Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Message;
use strict;
use warnings;
use Swarmage::Component;
our @ISA = qw(Swarmage::Component);

__PACKAGE__->mk_group_accessors(simple => qw(type data destination postback persistent source attr));
sub new
{
    my $class = shift;
    my %args  = @_;
    my $self  = $class->next::method(
        persistent => 1,
        attr => {},
        @_
    );
    return $self;
}

1;

__END__

=head1 NAME

Swarmage::Message - Base Message Class

=head1 DESCRIPTION

Swarmage::Message is a basic message abstraction that gets passed to the
message queue.

=head1 METHODS

=head2 new

=head2 type

=head2 data

=head2 destination

=head2 postback

=head2 source

=head2 attr

=head2 persistent

If true, the "persistent" flag will be set to "true". "false" otherwise
By default this value is true.

=cut