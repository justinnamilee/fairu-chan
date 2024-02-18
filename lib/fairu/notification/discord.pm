#!/usr/bin/perl

package fairu::notification::discord;


use strict;
use lib q[lib];


my $hook = undef;
my $template = undef;


sub init($)
{
  require Data::Validate::URI;

  my ($error, $config) = (0, @_);

  $config->{verify} = 1 unless defined($config->{verify});

  if (Data::Validate::URI::is_https_uri($config->{webhookUrl}))
  {
    require WebService::Discord::Webhook;
    my $d = WebService::Discord::Webhook->new(url => $config->{webhookUrl}, verify_SSL => $config->{verify});

    eval { $d->get };

    if ($@)
    {
      warn qq[Couldn't configure Discord: $@\n];
      $error++;
    }
    else
    {
      $hook = $d;
    }
  }
  else
  {
    warn qq[Couldn't configure Discord: '$config->{webhookUrl}' should be a valid HTTPS URL string\n];
    $error++;
  }

  if (length($config->{template}) > 0)
  {
    $template = $config->{template};
  }
  else
  {
    warn qq[Couldn't configure Discord: template should be a non-zero length string\n];
    $error++;
  }

  return ($error);
}

sub handler()
{
  return (sub { $hook->execute(sprintf($template, @_)) });
}


__PACKAGE__
