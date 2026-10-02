#!/usr/bin/perl

package fairu::notification::script;

use strict;
use lib q[lib];

my $loaded = undef;

sub new($)
{
  my ($error, $notification, $self, $config) = (0, {}, @_);

  if (ref($config) eq q[HASH] && length($config->{script}))
  {
    unless (defined($loaded))
    {
      $loaded = __PACKAGE__;
    }

    if (-x $config->{script})
    {
      $notification->{script} = $config->{script};
    }
    else
    {
      warn qq[Couldn't configure Script Notification: '$config->{script}' is not executable\n];
      $error++;
    }
  }
  else
  {
    warn qq[Couldn't configure Script Notification: config must be a HASH with key 'script'\n];
    $error++;
  }

  return ($error > 0 ? $error : bless $notification, $self);
}

sub handler(@)
{
  my ($self, $mode, $path) = @_;

  if ($mode eq q[event])
  {
    system($self->{script}, $path);

    if ($? == -1)
    {
      warn qq[Couldn't execute '$self->{script}': $!\n];
    }
    elsif ($? & 127)
    {
      warn sprintf(
        qq[Script '%s' died with signal %d\n],
        $self->{script},
        ($? & 127)
      );
    }
    elsif (($? >> 8) != 0)
    {
      warn sprintf(
        qq[Script '%s' exited with status %d\n],
        $self->{script},
        ($? >> 8)
      );
    }
  }
  else
  {
    warn qq[Unsupported mode '$mode' for Script Notification\n];
  }
}

__PACKAGE__
