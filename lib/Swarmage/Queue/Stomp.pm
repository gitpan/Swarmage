# $Id$
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved

package Swarmage::Queue::Stomp;
use strict;
use warnings;
use base qw(Swarmage::Queue);
use MIME::Base64;
use Net::Stomp;
use Storable qw(freeze thaw);
use Swarmage::Task;

__PACKAGE__->mk_group_accessors(simple => qw(connect_info subscriptions stomp));

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

sub insert
{
    my ($self, %opts) = @_;

    my $message = $opts{message} || Carp::croak("No message specified");
    my $queue   = $opts{queue}   ||
        ref($message) && $message->isa('Swarmage::Message') ? $message->destination : 
        Carp::croak("No queue specified")
    ;
    if ($queue !~ m{^/queue/}) {
        $queue = "/queue/$queue";
    }

    $self->ensure_connected->send({
        destination => $queue,
        body        => encode_base64( freeze( $message ) )
    }) or Carp::croak("Could not send message: $!");
}

sub fetch
{
    my ($self, %opts) = @_;

    my $queue   = $opts{queue} || Carp::croak("No queue specified");
    if ($queue !~ m{^/queue/}) {
        $queue = "/queue/$queue";
    }
    $self->ensure_subscribed( $queue );
    if ($self->stomp->can_read({ timeout => '0.1' })) {
        my $frame = $self->stomp->receive_frame;
        if ($frame->command eq 'ERROR') {
            die "received stomp error: " . $frame->body;
        }
        $self->stomp->ack({ frame => $frame });
        my $ret   =  eval { thaw( decode_base64($frame->body) ) };
        if (! $ret->attr) { $ret->attr({}) }
        $ret->attr->{frame} = $frame;
        die if $@;
        return $ret;
    }
    return;
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
        }) or Carp::croak("stomp->subscribe failed");
        $self->subscriptions->{ $destination }++;
    }
}

1;

__END__

=head1 NAME

Swarmage::Queue::Stomp - Stomp Implementation Of Swarmage::Queue

=head1 METHODS

=head2 new

=head2 insert

=head2 fetch

=head2 ensure_connected

=head2 ensure_subscribed

=cut
