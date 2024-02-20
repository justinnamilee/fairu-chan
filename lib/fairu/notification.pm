#!/usr/bin/perl

package fairu::notification;


use strict;
use lib q[lib];


use fairu::notification::discord;
# TODO: more notification types here?


my $notification = {};


sub init($)
{
  my ($error, $config) = (0, @_);

  if (ref($config) eq q[HASH])
  {
    foreach my $k (keys(%{$config}))
    {
      if (lc($config->{$k}->{type}) eq q[discord])
      {
        if (fairu::notification::discord::init($config->{$k}) == 0)
        {
          $notification->{$k} = fairu::notification::discord::handler();
        }
        else
        {
          warn qq[Couldn't configure notification($k)];
          $error++;
        }
      }
      # TODO: elsif (other notification types)
    }
  }
  elsif (defined($config))
  {
    warn qq[Couldn't configure notifications: meta->notification should be a HASH\n];
    $error++;
  }

  return ($error);
}

sub notify(@)
{
  #? we'll YOLO these notifications with eval for now, no need to crash
  eval { $notification->{$_}->(@_) for keys(%{$notification}) };
  warn qq[Ran into notification sending issues.\n] if ($@);
}


__PACKAGE__
