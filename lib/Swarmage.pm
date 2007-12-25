# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage.pm 36883 2007-12-25T04:15:57.892026Z daisuke  $
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

  use Swarmage

=head1 DESCRIPTION

This is a rewrite of previous Swarmage releases. So we're back to pre-alpha.

Swarmage brings you a complete Controlled Job Queue environment for high
performance, distributed tasks. Swarmage uses POE's asynchronous engine
to make a non-blocking worker possible.

Swarmage is a simple distributed job queue system.

Swarmage is comprised of Clients, Workers, and a Message Bus. Clients enqueue
tasks to be performed in the message queue:

  use strict;
  use Swarmage::Client;

  my $client = Swarmage::Client->new(
    hostname => "message.bus.hostname",
    login    => "foo",
    passcode => "bar"
  );
  $client->insert_task(
    Swarmage::Task->new(
      task_class => 'do_something_interesting',
      args       => $any_set_of_variables
    )
  );

That's it for the client. Now you just need a worker to execute your task.
On some other host (or, it could as well be the same host):

  use strict;
  use Swarmage::Worker;

  my $worker = Swarmage::Worker->new(
    hostname => "message.bus.hostname",
    login    => "foo",
    passcode => "bar",
    ability => {
      do_something_interesting => sub { "actual code" }
    }
  );
  $worker->work;

You execute this code, and the worker will keep on waiting for 'do_something_interesting' tasks,
and will execute them when it gets a chance. 

A Swarmage Cell is the smallest unit of operation in Swarmage, and it looks
something like this:

  package MyApp::Worker;
  use strict;
  use base qw(Swarmage::Worker);

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

