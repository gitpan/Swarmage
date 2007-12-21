use strict;
use inc::Module::Install;

name('Swarmage');

all_from('lib/Swarmage.pm');

requires('Class::Inspector');
requires('Class::Accessor::Fast');
requires('Class::Data::Inheritable');
requires('DBD::SQLite');
requires('DBI');
requires('Digest::MD5');
requires('Event::Notify');
requires('IO::Handle');
requires('Log::Dispatch::Handle');
requires('Log::Dispatch');
requires('MIME::Base64');
requires('POE');
requires('POE::Component::Generic');
requires('Storable');
requires('Sys::Hostname');
requires('Time::HiRes');
requires('UNIVERSAL::require');

build_requires('Test::More');

tests('t/*.t t/*/*.t');

auto_install;
WriteAll;