# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/CLI/Task.pm 2380 2007-09-03T00:40:36.249053Z daisuke  $
# 
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::CLI::Task;
use strict;
use warnings;
use App::CLI::Command;
use Config::Any;
use Swarmage::Client;
our @ISA = qw(App::CLI::Command);

sub options
{
    return (
        'hostname=s' => 'hostname',
        'port=i'     => 'port',
        'login=s'    => 'login',
        'passcode=s' => 'passcode',
        'config=s'   => 'config'
    );
}

sub run
{
    my $self = shift;

    $self->{port} ||= 61613;

    my $mode = shift @_;
    return unless $mode =~ /^insert$/;
    my $method = "do_$mode";
    $self->$method(@_);
}

sub do_insert
{
    my $self = shift;
    my $client = Swarmage::Client->new(
        storage => [
            {   class => 'Stomp',
                connect_info => {
                    hostname => $self->{hostname},
                    port     => $self->{port},
                    login    => $self->{login},
                    passcode => $self->{passcode},
                }
            }
        ]
    );

    my $file = $self->{config};
    my $config = Config::Any->load_files({files => [$file]});
    if ($config) {
        $config = $config->[0]->{$file};
    }

    foreach my $task ( @{ $config->{tasks} }) {
        $client->insert_task(
            Swarmage::Task->new(
                task_class => $task->{task},
                data       => $task->{data}
            )
        );
        print "Inserted new task '$task->{task}' to $self->{hostname}:$self->{port}\n";
    }
}

1;

