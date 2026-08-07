#!/usr/bin/perl

package fairu::notification::discord;


use strict;
use lib q[lib];


sub DEF_VRF() { 1 }


my $loaded = undef;


sub new($)
{
  my ($error, $notification, $self, $config) = (0, { hook => undef, template => undef }, @_);

  if (ref($config) eq q[HASH] && length($config->{template}) > 0)
  {
    unless (defined($loaded))
    {
      require Data::Validate::URI;
      require WebService::Discord::Webhook;
      require File::Basename;

      $loaded = __PACKAGE__;
    }

    $notification->{template} = $config->{template};
    my $verify = $config->{verify} // DEF_VRF;

    if (Data::Validate::URI::is_https_uri($config->{webhookUrl}))
    {
      my $d = WebService::Discord::Webhook->new(url => $config->{webhookUrl}, verify_SSL => $config->{verify});

      #? do a connection test / get the webhook thingie
      eval { $d->get };

      if ($@)
      {
        warn qq[Couldn't "get" on Discord webhook: $@\n];
        $error++;
      }
      else
      {
        $notification->{hook} = $d;
      }
    }
    else
    {
      warn qq[Couldn't configure Discord: '$config->{webhookUrl}' should be a valid HTTPS URL\n];
      $error++;
    }
  }
  else
  {
    warn qq[Couldn't configure Discord: config should be a HASH and template should be non-zero length string\n];
    $error++;
  }

  return ($error > 0 ? $error : (bless $notification, $self));
}

sub handler(@)
{
  my ($self, $mode, @data) = @_;

  if ($mode eq 'event')
  {
    $self->{hook}->execute(sprintf($self->{template}, (File::Basename::fileparse($data[0]))[0]));
  }
  else
  {
    $self->{hook}->execute(sprintf($self->{template}, @data));
  }
}


__PACKAGE__
