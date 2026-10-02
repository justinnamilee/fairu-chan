#!/usr/bin/perl

package fairu::notification::script;

use strict;
use fairu::chan::message;


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
      warn fairu::chan::message::get(script_no_exec => $config->{script});
      $error++;
    }
  }
  else
  {
    warn fairu::chan::message::get(q[script_conf_not_valid]);
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
      warn fairu::chan::message::get(script_bad_exec => $self->{script}, $!);
    }
    elsif ($? & 127)
    {
      warn fairu::chan::message::get(script_die_signal => $self->{script}, ($? & 127));
    }
    elsif (($? >> 8) != 0)
    {
      warn fairu::chan::message::get(script_die_status => $self->{script}, ($? >> 8));
    }
  }
  else
  {
    warn fairu::chan::message::get(script_mode_not_valid => $mode);
  }
}

__PACKAGE__
