# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/Queue.pm 2910 2007-09-30T13:07:46.115785Z daisuke  $
# 
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Queue;
use strict;
use warnings;
use Swarmage::Component;
our @ISA = qw(Swarmage::Component);

sub fetch {}
sub insert {}

1;

__END__

=head1 NAME

Swarmage::Queue - Queue Interface

=head1 DESCRIPTION

Swarmage::Queue is a facade that abstracts the backend queue implementation.

Swarmage was first implemented because we wanted a job queue that doesn't
use an RDBMS, but it doesn't mean that we need to restrict ourselves to
a particular backend. Swarmage queue just needs to implement this interface

=head1 METHODS

=head2 fetch(%opts)

=head2 insert(%opts)

=cut
