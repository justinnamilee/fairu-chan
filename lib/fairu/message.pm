#!/usr/bin/perl

package fairu::message;

use strict;
use fairu::message::english;


#* globals *#

my $default = fairu::message::english::interface;
my $interface = $default;
my $name = fairu::message::english::name;


#* public functions *#

sub get($;@)
{
  my ($key, @f) = @_;
  my $ret = sprintf($default->(q[message_key]), $name, $key);

  if (defined(my $msg = $interface->($key)))
  {
    $ret = sprintf($msg, @f);
  }

  return $ret;
}

sub set($)
{
  my ($language) = @_;

  my $require = qq[fairu/chan/message/$language.pm];
  my $package = qq[fairu::message::$language];

  if (eval { require $require })
  {
    $interface = $package->interface;
    $name = $package->name;
  }
  else
  {
    die get(message_language => $language);
  }
}


__PACKAGE__
