# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage.pm 3749 2007-10-19T05:00:46.962903Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage;
use strict;
use vars qw($VERSION);
$VERSION = '0.00006';

1;

__END__

=head1 NAME

Swarmage - A Distributed Job Queue

=head1 SYNOPSIS

  swarmage task insert --config=config.yml
  swarmage worker --module=MyApp::Worker

=head1 DESCRIPTION

XXX Warning: Alpha grade software. All API still subject to change.
RFCs are welcome and will be considered ASAP XXX

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

The above code can also be written in a more object oriented manner.
Just override the work_once subroutine

  package MyApp::Worker;
  use strict;
  use base qw(Swarmage::Worker);

  __PACKAGE__->register_abilities('do_something_interesting');

  sub work_once { "actual code" }

  # in your worker script
  use strict;
  use MyApp::Worker;

  my $worker = MyApp::Worker->new(
    hostname => "message.bus.hostname",
    login    => "foo",
    passcode => "bar",
  );
  $worker->work;

Actually, once you write MyApp::Worker, you can just use the swarmage script
that comes with this distribution:

  swarmage worker --module=MyApp::Worker \
    --hostname=message.bus.hostname \
    --login=foo \
    --passcode=bar

...And if you don't have to do any special pre-processing, you can just
specify a task within a config file 

  swarmage task insert --config=foo.yml

=head1 TASKS

Tasks are simply a combination of 'task_class', and a set of arbitrary data.
It's completely up to the client and the worker to make any sense out of it.

=head1 MESSAGE BUS

Swarmage relies on message queues such as ActiveMQ as the underlying
message layer.

There's an unfinished attempt at making a small scale DBIC-based message layer,
but so far I have no plans to work on it. Patches are more than welcome

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

