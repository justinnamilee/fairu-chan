#!/usr/bin/perl

package fairu::notification;


use strict;
use lib q[lib];


use fairu::notification::discord;
# TODO: more notification types here?


sub TYPE() { qw[event information debug] }


my $notification = { map { $_ => [] } TYPE };


sub init($)
{
  my ($error, $config) = (0, @_);

  if (ref($config) eq q[HASH])
  {
    foreach my $k (keys(%{$config}))
    {
      if (lc($config->{$k}->{type}) eq q[discord])
      {
        if (ref(my $n = fairu::notification::discord->new($config->{$k})))
        {
          foreach my $t (TYPE)
          {
            push(@{$notification->{$t}}, $n) if lc($config->{$k}->{for}) eq $t || !exists($config->{$k}->{for});
          }
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

sub send($@)
{
  my ($mode, @data) = @_;

  if (ref($notification->{$mode}) eq q[ARRAY])
  {
    #? we'll YOLO these notifications with eval for now, no need to crash
    eval { $_->handler(@data) for @{$notification->{$mode}} };
    warn qq[Ran into notification sending issues.\n] if ($@);
  }
  else
  {
    warn qq[Unknown notification type '$mode'.\n];
  }
}


__PACKAGE__
