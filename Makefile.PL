#!perl
use strict;
use inc::Module::Install;

name('Swarmage');
all_from('lib/Swarmage.pm');

requires('App::CLI');
requires('Class::Accessor::Grouped');
requires('Class::C3::Componentised');
requires('Class::Inspector');
requires('Class::Null'); # Only because we haven't implemented the logger
requires('Config::Any');
requires('Digest::MD5');
requires('MIME::Base64');
requires('Net::Stomp');
requires('Storable');
requires('UNIVERSAL::isa');
requires('UNIVERSAL::require');

tests 't/*.t t/*/*.t';
install_script('script/swarmage');

&WriteAll;