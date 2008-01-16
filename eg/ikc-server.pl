use strict;
use POE qw(Component::IKC::Server);
use lib("lib");
use Swarmage::Task;

BEGIN
{
    if ($ENV{IKC_DEBUG}) {
        no warnings 'redefine';
        *POE::Component::IKC::Responder::DEBUG = sub { 1 };
        *POE::Component::IKC::Responder::Object::DEBUG = sub { 1 };
    }
}

POE::Session->create(
    inline_states => {
        _start => sub {
            my $kernel = $_[KERNEL];
            $kernel->alias_set('queue');
            create_ikc_server(
                ip => '127.0.0.1',
                port => 9999,
                name => "ServerName"
            );
            $kernel->call('IKC' => 'publish', 'queue' => [ qw(pump) ])
                or die "publish failed";
            $kernel->call('IKC' => 'monitor', '*' => {
                register => 'remote_register',
                unregister => 'remote_unregister',
                subscribe  => 'remote_subscribe',
                unsubscribe => 'remote_unsubscribe',
            });
        },
        pump => sub {
            if (rand() > 0.4) {
                warn "Not sending";
            } else {
                warn "Sending!";
                return [
                    (
                        Swarmage::Task->new(
                            type => 'factorial',
                            data => int(rand(10))
                        )
                    ) x int(rand(5))
                ];
            }
            return ();
        },
        remote_register    => sub { warn "register" },
        remote_unregister  => sub { warn "unregister" },
        remote_subscribe   => sub { warn "subscribe" },
        remote_unsubscribe => sub { warn "unsubscribe" },
    }
);
POE::Kernel->run;
