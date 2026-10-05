#!/usr/bin/perl

package fairu::notification;


use strict;
use fairu::message;


sub TYPE() { qw[event information debug] }


my $notification = undef;
my %interface = ();


sub init($)
{
  my ($config) = @_;
  my ($error, $new) = (0, { map { $_ => [] } TYPE });

  if (ref($config) eq q[HASH])
  {
    foreach my $k (keys(%{$config}))
    {
      my $type = lc($config->{$k}->{type});

      unless (exists($interface{$type}))
      {
        my $require = qq[fairu/notification/$type.pm];

        if (eval { require $require })
        {
          $interface{$type} = qq[fairu::notification::$type];
        }
        else
        {
          warn fairu::message::get(notif_compile_failed => $k);
          $error++;

          next;
        }
      }

      if (ref(my $n = $interface{$type}->new($config->{$k})))
      {
        foreach my $t (TYPE)
        {
          push(@{$new->{$t}}, $n) if lc($config->{$k}->{for}) eq $t || !exists($config->{$k}->{for});
        }
      }
      else
      {
        warn fairu::message::get(notif_conf_failed => $k);
        $error++;
      }
    }
  }
  elsif (defined($config))
  {
    warn fairu::message::get(q[notif_conf_not_valid]);
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
    warn fairu::message::get(q[notif_send_failed]) if ($@);
  }
  else
  {
    warn fairu::message::get(notif_mode_not_valid => $mode);
  }
}


__PACKAGE__
