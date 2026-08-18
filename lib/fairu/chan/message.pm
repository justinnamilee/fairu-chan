#!/usr/bin/perl

use strict;

use fairu::chan::message::english;

my $default = fairu::chan::message::english->interface;
my $interface = $default;


sub get($;@)
{
  my ($key, @f) = @_;
  my $ret = sprintf($default->(q[bad_message_key]), $interface->name, $key);

  if (defined(my $msg = $interface->($key)))
  {
    $ret = sprintf($msg, @f);
  }

  return $ret;
}

sub set($)
{
  my ($language) = @_;
  my $package = qq[fairu::chan::message::$language];

  if (eval { require $package })
  {
    $interface = $package->interface;
  }
  else
  {
    die get(bad_message_language => $language);
  }
}


__PACKAGE__
