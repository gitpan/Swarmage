#!perl
use strict;
use inc::Module::Install;

name('Swarmage');
all_from('lib/Swarmage.pm');

requires('BerkeleyDB');
requires('Carp');
requires('Class::Inspector');
requires('Class::Accessor::Fast');
requires('Class::Data::Inheritable');
requires('DBI');
requires('Digest::MD5');
requires('Event::Notify');
requires('IO::Handle');
requires('Log::Dispatch::Handle');
requires('Log::Dispatch');
requires('MIME::Base64');
requires('Path::Class');
requires('POE');
requires('POE::Component::Generic');
requires('POE::Component::IKC');
requires('Storable');
requires('Sys::Hostname');
requires('Time::HiRes');
requires('UNIVERSAL::require');

build_requires("Test::More");
recommends('Test::Pod');
recommends('Test::Pod::Coverage');

tests ('t/*.t t/*/*.t t/*/*/*.t');

WriteAll;