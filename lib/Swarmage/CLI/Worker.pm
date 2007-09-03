# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/CLI/Worker.pm 2425 2007-09-03T10:56:40.325353Z daisuke  $
# 
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::CLI::Worker;
use strict;
use warnings;
use App::CLI::Command;
use Class::Inspector;
our @ISA = qw(App::CLI::Command);

sub options
{
    return (
        'hostname=s' => 'hostname',
        'port=i'     => 'port',
        'login=s'    => 'login',
        'passcode=s' => 'passcode',
        'file=s'     => 'file',
        'module=s'   => 'module',
    );
}

sub run
{
    my $self   = shift;

    my $worker;
    my %args = (
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
    if (my $module = $self->{module}) {
        if (! Class::Inspector->loaded( $module )) {
            require UNIVERSAL::require;
            $module->require or die ;
        }

        $worker = $module->new(%args);
    } elsif (my $file = $self->{file}) {
        die "Currently unimplemented";
#        $worker = Swarmage::Worker::Run->new(
#            filename => $file,
#            %args
#        )
    } else {
        return $self->usage;
    }
    
    $worker->work;
}

1;

__END__

=head1 NAME

Swarmage::CLI::Worker - Invoke Worker Processes

=head1 SYNOPSIS

  swarmage worker --module=MyApp::Worker \
    --hostname=example.com \
    [--port=61613] \
    [--login=username] \
    [--passcode=password]

=head1 DESCRIPTION

=head1 METHODS

These are internal. You can safely ignore them if you are just using this
from the command line

=head2 options

=head2 run

=cut
