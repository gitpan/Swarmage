# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/Worker.pm 2909 2007-09-30T13:06:51.115468Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Worker;
use strict;
use warnings;
use Swarmage::Client;
use Swarmage::Log;
our @ISA = qw(Swarmage::Client);

__PACKAGE__->mk_group_accessors(simple => qw(delay log is_running callbacks));
__PACKAGE__->mk_classaccessor('__abilities' => []);

sub abilities
{
    my $class = shift;
    my @ret   = @{ $class->__abilities || [] };
    if (ref $class && $class->isa(__PACKAGE__)) {
        push @ret, @{ $class->callbacks->{__abilities} || [] };
    }

    if (@_) {
        $class->__abilities([ @_ ]);
    }
    return wantarray ? @ret : \@ret;
}

sub new
{
    my $class = shift;
    my %args  = @_;
    my $self  = $class->next::method(@_);

    if (! exists $args{delay}) {
        $args{delay} = 0.5;
    }
    if (! exists $args{log}) {
        $args{log} = Swarmage::Log->new;
    }

    foreach my $hash qw(callbacks) {
        $self->$hash({});
        while (my ($name, $value) = each %{ $args{$hash} || {} }) {
            $self->$hash->{$name} = $value;
        }
    }
    
    while( my ($name, $code) = each %{ $args{ability} || $args{abilities} || {}}) {
        $self->_register_ability($name, $code);
    }

    $self->delay($args{delay});
    $self->log( $args{log} );
    return $self;
}

sub _register_ability
{
    my ($self, $name, $code) = @_;
    $self->callbacks->{__abilities}{ $name } = $code;
}

sub work
{
    my ($self, $c) = @_;

    $self->is_running(1);
    while ($self->is_running()) {
        my @abilities = $self->abilities;
        my @tasks;
        eval {
            @tasks = $self->find_task(map { "/queue/task/$_" } @abilities);
        };
        if ($@) {
            print STDERR "find_task() failed: $@\ncontinuing anyway...\n";
            goto SLEEP;
        }
        if (! @tasks) {
            goto SLEEP;
        }

        foreach my $task (@tasks) {
            eval {
                my $ret = $self->work_once($task);
                $self->post_work($task);
                $self->finalize_work($task);
                if (my $destination = $task->postback) {
                    $self->insert_task(
                        Swarmage::Message->new(
                            destination => $destination,
                            data        => $ret
                        )
                    );
                }
            };
            warn if $@;
        }
SLEEP:
        sleep($self->delay);
    }
}

sub work_once
{
    my ($self, $task) = @_;
    my $ret = eval {
        my $cb = $self->callbacks->{__abilities}{$task->task_class};
        return $cb ? $cb->($self, $task) : undef;
    };
    die if $@;
    return $ret;
}

sub post_work
{
    my ($self, $task) = @_;
    my $ret = eval {
        my $cb = $self->callbacks->{post_work};
        return $cb ? $cb->($self, $task) : undef;
    };
    die if $@;
}

sub finalize_work
{
    my ($self, $task) = @_;
}

1;

__END__

=head1 NAME

Swarmage::Worker - Swarmage Worker

=head1 SYNOPSIS

  # Use it by subclassing
  package MyApp::Worker;
  use strict;
  use base qw(Swarmage::Worker);
  __PACKAGE__->abilities('name_of_ability');

  sub work_once
  {
    my ($self, $task) = @_;
    # do something interesting
  }

  # Use it by passing a callback

=head1 METHODS

=head2 new

=head2 abilities

Get/Set the abilities for the client

=head2 work

Starts the work cycle.

=head2 work_once

Does the actual work. The return value will be used as the value to be postback,
if postback is specified.

=head2 post_work

=head2 finalize_work

=cut
