# $Id: /mirror/perl/Swarmage/trunk/lib/Swarmage/Worker/Generic.pm 36876 2007-12-25T03:11:23.372766Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Swarmage::Worker::Generic;
use strict;
use warnings;

sub new
{
    my $class = shift;
    my %args  = @_;
    POE::Component::Generic->spawn(
        verbose => 1,
        package => "Swarmage::Worker::Generic::Slave",
        object_options => [ %args ],
        methods        => [ qw(work) ]
    );
}

package Swarmage::Worker::Generic::Slave;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors($_) for qw(slave);

sub new
{
    my $class = shift;
    my %args  = @_;

    my $slave_pkg = Swarmage::Util::load_module($args{module});
    my $slave     = $slave_pkg->new( %{ $args{config} || {} } );
    bless {
        slave => $slave
    }, $class;
}


sub work
{
    my ($self, $task) = @_;
    warn $self->slave . " -> work";
    my @ret = eval { $self->slave->work( $task ) };
    warn if $@;
    return @ret;
}

1;

__END__

=head1 NAME

Swarmage::Worker::Generic - POE::Component::Generic Wrapper For Swarmage::Worker

=head1 METHODS

=head2 new

=cut
