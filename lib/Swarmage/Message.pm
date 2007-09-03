# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/Message.pm 2425 2007-09-03T10:56:40.325353Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Message;
use strict;
use warnings;
use Swarmage::Component;
our @ISA = qw(Swarmage::Component);

__PACKAGE__->mk_group_accessors(simple => qw(type data destination postback));
sub new
{
    my $class = shift;
    my %args  = @_;
    my $self  = $class->next::method(@_);
    foreach my $arg qw(type data destination postback) {
        $self->$arg($args{$arg}) if exists $args{$arg};
    }
    return $self;
}

1;

__END__

=head1 NAME

Swarmage::Message

=head1 METHODS

=head2 new

=cut