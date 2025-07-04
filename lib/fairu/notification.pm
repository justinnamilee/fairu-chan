#!/usr/bin/perl

package fairu::notification;


use strict;
use lib q[lib];


use fairu::notification::discord;
use fairu::notification::plex;
# TODO: more notification types here?


sub TYPE() { qw[event information debug] }


my $notification = undef;


sub init($)
{
  my ($error, $new, $config) = (0, { map { $_ => [] } TYPE }, @_);

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
            push(@{$new->{$t}}, $n) if lc($config->{$k}->{for}) eq $t || !exists($config->{$k}->{for});
          }
        }
        else
        {
          warn qq[Couldn't configure notification($k)];
          $error++;
        }
      }
      elsif (lc($config->{$k}->{type}) eq q[plex])
      {
        if (ref(my $n = fairu::notification::plex->new($config->{$k})))
        {
          foreach my $t (TYPE)
          {
            push(@{$new->{$t}}, $n) if lc($config->{$k}->{for}) eq $t || !exists($config->{$k}->{for});
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

  if (!$error)
  {
    # if we're good, swap to new notifications
    $notification = $new;
  }

  return ($error);
}

sub send($@)
{
  my ($mode, @data) = @_;

  if (ref($notification->{$mode}) eq q[ARRAY])
  {
    #? we'll YOLO these notifications with eval for now, no need to crash
    eval { $_->handler($mode, @data) for @{$notification->{$mode}} };
    warn qq[Ran into notification sending issues.\n] if ($@);
  }
  else
  {
    warn qq[Unknown notification type '$mode'.\n];
  }
}


__PACKAGE__
