#!/usr/bin/perl

package fairu::chan::message;

use strict;

use fairu::chan::message::english;


my $default = fairu::chan::message::english::interface;
my $interface = $default;
my $name = fairu::chan::message::english::name;


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
  my $package = qq[fairu::chan::message::$language];

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
