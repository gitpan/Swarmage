# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/Storage/Stomp.pm 2425 2007-09-03T10:56:40.325353Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Storage::Stomp;
use strict;
use warnings;
use Swarmage::Component;
our @ISA = qw(Swarmage::Component);
use MIME::Base64;
use Net::Stomp;
use Storable qw(freeze thaw);
use Swarmage::Task;

__PACKAGE__->mk_group_accessors(simple => qw(connect_info subscriptions stomp));

# aliases
*fetch = \&fetch_queue;
*insert = \&insert_queue;

sub new
{
    my $class = shift;
    my %args  = @_;
    my $self  = $class->next::method(@_);

    my $connect_info = $args{connect_info} || Carp::croak("No connect_info provided");
    $connect_info->{port}     ||= 61613;
    if (! $connect_info || (! $connect_info->{hostname} || ! $connect_info->{port} || ! $connect_info->{login} || ! $connect_info->{passcode})) {
        Carp::croak("No connect_info provided");
    }
    $self->connect_info($connect_info);

    return $self;
}

sub insert_queue
{
    my ($self, $message) = @_;
    my $destination = $message->destination;
    if ($destination !~ m{^/queue/}) {
        $destination = "/queue/$destination";
    }

    if (my $postback = $message->postback) {
        $self->ensure_subscribed( $postback );
    }

    $self->ensure_connected->send({
        destination => $destination,
        body        => encode_base64( freeze( $message ) )
    }) or Carp::croak("Could not send message: $!");
}

sub fetch_queue
{
    my ($self, $destination) = @_;

    if ($destination !~ m{^/queue/}) {
        $destination = "/queue/$destination";
    }
    $self->ensure_subscribed( $destination );
    if ($self->stomp->can_read({ timeout => '0.1' })) {
        my $frame = $self->stomp->receive_frame;
        if ($frame->command eq 'ERROR') {
            die "received stomp error: " . $frame->body;
        }
        my $ret   =  eval { thaw( decode_base64($frame->body) ) };
        if (! $ret->attr) { $ret->attr({}) }
        $ret->attr->{frame} = $frame;
        die if $@;
        return $ret;
    }
    return;
}

sub finalize_task
{
    my ($self, $task) = @_;
    $self->ensure_connected->ack({ frame => $task->attr->{frame} });
}

sub ensure_connected
{
    my $self = shift;
    my $stomp = $self->stomp;
    if (! $stomp || ! $stomp->socket->connected || $stomp->socket->eof) {
        $stomp->socket->close if $stomp;
        my $connect_info = $self->connect_info;
        $stomp = Net::Stomp->new({
            hostname => $connect_info->{hostname},
            port => $connect_info->{port},
        });
        $stomp->connect({
            login => $connect_info->{login},
            passcode => $connect_info->{passcode},
        });
        $self->stomp($stomp);
        $self->subscriptions({});
    }
    return $stomp;
}

sub ensure_subscribed
{
    my ($self, $destination) = @_;

    my $stomp = $self->ensure_connected();
    if ($destination !~ m{^/queue/}) {
        $destination = "/queue/$destination";
    }
    if (! $self->subscriptions->{ $destination }) {
        # hmm, no subscription... let me subscribe to this queue
        my $stomp = $self->stomp;
        $stomp->subscribe({
            destination => $destination,
            ack         => 'client',
            'activemq.prefetchSize' => 1 # This needs to be configurable
        }) or Carp::croak("stomp->subscribe failed");
        $self->subscriptions->{ $destination }++;
    }
}

1;

__END__

=head1 NAME

Swarmage::Storage::Stomp - STOMP-Based Backend For Swarmage

=head1 METHODS

=head2 new

=head2 ensure_connected

Makes sure that we have a connected Net::Stomp client.
Returns the Net::Stomp object.

=head2 ensure_subscribed($desination)

Makes sure that we have subscribed to the given destination

=head2 fetch($destination) / fetch_queue($destination)

Fetch the next message in the queue, in the named queue.
If $destination starts with "/queue/", then that name is used. Otherwise
"/queue/" is prepended to the destination

=head2 insert / insert_queue

=head2 finalize / finalize_task 

=cut