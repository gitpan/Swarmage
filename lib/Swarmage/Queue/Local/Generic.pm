# $Id: /mirror/perl/Swarmage/branches/2.0-redo/lib/Swarmage/Queue/Local/Generic.pm 36144 2007-12-21T01:05:54.525393Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Queue::Local::Generic;
use strict;
use warnings;
use base qw(Swarmage::Queue::DBI::Generic);

__PACKAGE__->mk_accessors($_) for qw(filename);
__PACKAGE__->backend_class( 'Swarmage::Queue::Local');

sub new
{
    my $class = shift;
    my %args  = @_;
    my $filename = $args{filename} || "local_queue-$$.db";

    my $self = $class->SUPER::new(
        connect_info => [
            "dbi:SQLite:dbname=$filename",
            undef,
            undef,
            { RaiseError => 1, AutoCommit => 1 }
        ]
    );
    $self->filename( $filename );
    return $self;
}

1;

__END__

=head1 NAME

Swarmage::Queue::Local::Generic - POE::Component::Generic Wrapper For Swarmage::Queue::Local

=head1 METHODS

=head2 new

=cut

