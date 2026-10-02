#!/usr/bin/perl

package fairu::notification::plex;


use strict;
use lib q[lib];


use fairu::chan::message;


sub DEF_URL() { q[%s/library/sections/%s/refresh?path=%s&X-Plex-Token=%s] }


my $loaded = undef;


sub new($)
{
  my ($error, $notification, $self, $config) = (0, {}, @_);

  if (ref($config) eq q[HASH] && length($config->{webhookUrl}) && ref($config->{libraries}) eq q[HASH] && length($config->{webhookToken}))
  {
    unless (defined($loaded))
    {
      require HTTP::Tiny;
      require URI::Escape;
      require File::Basename;
      require Data::Validate::URI;

      $loaded = __PACKAGE__;
    }

    if (Data::Validate::URI::is_http_uri($config->{webhookUrl}))
    {
      (my $base = $config->{webhookUrl}) =~ s|/+$||;

      $notification->{url}   = $base;
      $notification->{token} = $config->{webhookToken};
      $notification->{lib}   = $config->{libraries};
      $notification->{http}  = HTTP::Tiny->new(agent => q[PlexScan/1.0]);
    }
    else
    {
      warn fairu::chan::message::get(plex_url_not_valid => $config->{webhookUrl});
      $error++;
    }
  }
  else
  {
    warn fairu::chan::message::get(q[plex_conf_not_valid]);
    $error++;
  }

  return ($error > 0 ? $error : bless $notification, $self);
}

sub handler(@)
{
  my ($self, $mode, $path) = @_;

  if ($mode eq q[event])
  {
    (my $dir = (File::Basename::fileparse($path))[1]) =~ s|/+$||;
    my $section = undef;

    foreach my $k (keys(%{$self->{lib}}))
    {
      if (index($dir, $k) == 0)
      {
        $section = $self->{lib}->{$k};
        last;
      }
    }

    if (defined($section) && $section > 0)
    {
      my $enc = URI::Escape::uri_escape_utf8($dir);

      my $url = sprintf(DEF_URL, $self->{url}, $section, $enc, $self->{token});
      my $res = $self->{http}->get($url);

      unless ($res->{success})
      {
        warn fairu::chan::message::get(plex_no_scan => $dir, $url, $res->{status}, $res->{reason});
      }
    }
  }
  else
  {
    warn fairu::chan::message::get(plex_mode_not_valid => $mode);
  }
}


__PACKAGE__
