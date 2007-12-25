# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/Client.pm 36876 2007-12-25T03:11:23.372766Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Client;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Swarmage::Task;
use Swarmage::Util;
use Sys::Hostname();

__PACKAGE__->mk_accessors($_) for qw(queue);

sub new
{
    my $class = shift;
    my %args  = @_;

    my $queue_config = $args{queue};
    my $queue_pkg = Swarmage::Util::load_module(
        $queue_config->{module} || 'DBI::Generic',
        'Swarmage::Queue'
    );

    my $queue = $queue_pkg->new(
        %{ $queue_config->{config} || {} },
    );

    return bless {
        queue => $queue,
    }, $class;
}

sub post_respond
{
    my ($self, $task) = @_;

    my $postback = join('-', 'postback', Sys::Hostname::hostname(), $$, time(), rand(1000));
    $task->postback( $postback );
    $self->queue->enqueue($task);
    my ($response) = $self->queue->poll_wait( task_types => [ $postback ] );
    return wantarray ? @{$response->data || []} : $response->data;
}

1;

__END__

=head1 NAME

Swarmage::Client - Blocking Client For Swarmage

=head1 SYNOPSIS

  use Swarmage::Client;
  my $client = Swarmage::Client->new(
    queue => {
      module => "DBI::Generic",
      config => {
        connect_info => [ ... ]
      }
    }
  );
  my $response = $client->post_response(
    Swarmage::Task->new(
      type => $task_type,
      data => ....,
    );
  );

=head1 METHODS

=head2 new

=head2 post_respond

=cut
