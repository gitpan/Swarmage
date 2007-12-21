# $Id: /mirror/perl/Swarmage/branches/2.0-redo/lib/Swarmage.pm 36147 2007-12-21T01:21:44.144725Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage;
use strict;
use warnings;
use Swarmage::Drone;
our $VERSION = '0.01000';

1;

__END__

=head1 NAME

Swarmage - A Distributed Job Queue

=head1 SYNOPSIS

  use Swarmage;

=head1 DESCRIPTION

This is a rewrite of previous Swarmage releases. So we're back to pre-alpha.

Swarmage brings you a complete Controlled Job Queue environment for high
performance, distributed tasks. Swarmage uses POE's asynchronous engine
to make a non-blocking worker possible.

=head1 TERMS

=head2 Cell

A Swarmage Cell consists of one or more Drones which are attatched to a
Queue.

=head2 Drone

A Swarmage Drone is the master process that controls multiple Workers.
The Workers may consist of completely independent tasks

=head2 Worker

A Swarmage Worker is a process that is spawned by the Drone.

=head1 SWARMAGE CELL

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

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut