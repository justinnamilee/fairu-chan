#!/usr/bin/perl

package fairu::notification::script;

use strict;
use fairu::message;


sub new($)
{
  my ($self, $config) = @_;
  my ($error, $notification) = (0, {});

  if (ref($config) eq q[HASH] && length($config->{script}))
  {
    if (-x $config->{script})
    {
      $notification->{script} = $config->{script};
    }
    else
    {
      warn fairu::message::get(script_no_exec => $config->{script});
      $error++;
    }
  }
  else
  {
    warn fairu::message::get(q[script_conf_not_valid]);
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
      warn fairu::message::get(script_bad_exec => $self->{script}, $!);
    }
    elsif ($? & 127)
    {
      warn fairu::message::get(script_die_signal => $self->{script}, ($? & 127));
    }
    elsif (($? >> 8) != 0)
    {
      warn fairu::message::get(script_die_status => $self->{script}, ($? >> 8));
    }
  }
}


__PACKAGE__
