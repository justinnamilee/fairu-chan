#!/usr/bin/perl

package fairu::message;

use strict;
use fairu::message::english;


#* globals *#

my $default = fairu::message::english->interface;
my $name = fairu::message::english->name;

my $interface = $default;
my %loaded = (english => 1);

#* public functions *#

sub get($;@)
{
  my ($key, @f) = @_;

  my $msg = $interface->($key);
  my $ret = defined($msg)
    ? sprintf($msg, @f)
    : sprintf($default->(q[message_key]), $name, $key);

  return $ret;
}

sub language($)
{
  my ($language) = @_;

  my $require = qq[fairu/chan/message/$language.pm];
  my $package = qq[fairu::message::$language];
  my $success = 0;

  if ($loaded{$language} || eval { require $require })
  {
    $success = 1;
    $loaded{$language}++;

    $interface = $package->interface;
    $name = $package->name;
  }

  return ($success);
}


__PACKAGE__
