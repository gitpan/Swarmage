# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage.pm 38164 2008-01-07T05:39:28.711694Z daisuke  $
#
# Copyright (c) 2007-2008 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage;
use strict;
use warnings;
use Swarmage::Drone;
our $VERSION = '0.01001';

1;

__END__

=head1 NAME

Swarmage - A Distributed Job Queue

=head1 SYNOPSIS

  use Swarmage;
  Swarmage::Drone->new( ... ); # see docs for Swarmage::Drone

=head1 DESCRIPTION

This is a rewrite of previous Swarmage releases. So we're back to pre-alpha.

Swarmage brings you a complete Controlled Job Queue environment for high
performance, distributed tasks. Swarmage uses POE's asynchronous engine
to make a non-blocking worker possible.

A Swarmage Cell is the smallest unit of operation in Swarmage, and it looks
something like this:

  ----------------
  | Global Queue |
  ----------------
     ^ |
     | v
  ---------
  | Drone |--------------------
  ---------                   |
      |                       v
      |  ----------     ---------------
      |--| Worker |-----| Local Queue |
      |  ----------  |  ---------------
      |  ----------  |
      |--| Worker |--|
      |  ----------  |
      |  ----------  |
      |--| Worker |--|
      |  ----------  |
      .              .
      .              .
      .              .

There is a Global Queue, which Drones attatch to. This is where users typically
queue their tasks. Drones take tasks that their Workers can handle. This is
done by specifying which Workers can handle which types of tasks in the
initialization of Drones.

Once the Drone receives possibly multiple tasks from the Global Queue, the
tasks are inserted into what's called a Local Queue. Drones keep track of
what tasks are currently handle by looking at this Local Queue, and in
turn Workers attempt to grab tasks the Local Queue.

Workers only knows about the Local Queue. This is to avoid unnecessary polling
by the Workers to the Global Queue. Workers can also pass tasks between
other Workers in the local Drone group by enqueuing new tasks to the Local
Queue.

Once the task is completed, the Drone is notified, and the task will be
finalized.

Please consult the documentation for Swarmage::Drone and Swarmage::Worker for
more details on how the components interact with each other

=head1 SWARMAGE QUEUES

There are several queue types available for Swarmage. Available queues are:

=head2 Swarmage::Queue::DBI

Use a database as your queue. This queue should generally be used in 
conjunction with Swarmage::Queue::DBI::Generic, which allows you asynchronous
access to DBI.

=head2 Swarmage::Queue::BerkeleyDB

Uses a BerkeleyDB database as your queue. The Local Queue is currently
implemented with this.

=head2 Swarmage::Queue::IKC::Client

# WARNINGS: This is still in development

Uses POE::Component::IKC::Client as your queue. The queue asks a remote POE
kernel for new tasks. Use this if you have a remote POE process that's
generating the tasks for you.

=head1 SWARMAGE WORKER

Swarmage Workers come in couple of different flavors to allow asynchronous
execution of tasks.

=head2 Swarmage::Worker::Generic

Swarmage::Worker::Generic uses POE::Component::Generic to spawn off another
process to do the dirty work.

=head2 Swarmage::Worker::POE

Swarmage::Worker::POE connects to another POE session (for example, Gungho)
and let id do its job.

=head1 AUTHOR

Copyright (c) 2007-2008 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

