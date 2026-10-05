#!/usr/bin/perl

package fairu::notification::plex;


use strict;
use fairu::message;
use File::Basename;


#* statics *#

sub DEF_URL() { q[%s/library/sections/%s/refresh?path=%s&X-Plex-Token=%s] }


#* globals *#

my $loaded = undef;


#* internal stuff *#

sub _load
{
  my $error = 0;

  if (!$loaded)
  {
    ++$error && warn fairu::message::get(generic_require_failed => q[Data::Validate::URI])
      unless eval { require Data::Validate::URI };

    ++$error && warn fairu::message::get(generic_require_failed => q[HTTP::Tiny])
      unless eval { require HTTP::Tiny };

    ++$error && warn fairu::message::get(generic_require_failed => q[URI::Escape])
      unless eval { require URI::Escape };

    $loaded = __PACKAGE__;
  }

  return ($error);
}


#* public methods *#

sub new($)
{
  my ($self, $config) = @_;
  my ($notification, $error) = ({}, $self->_load);

  unless ($error)
  {
    if (ref($config) eq q[HASH] && length($config->{webhookUrl}) && ref($config->{libraries}) eq q[HASH] && length($config->{webhookToken}))
    {
      if (Data::Validate::URI::is_web_uri($config->{webhookUrl}))
      {
        (my $base = $config->{webhookUrl}) =~ s|/+$||;

        $notification->{url}   = $base;
        $notification->{token} = $config->{webhookToken};
        $notification->{lib}   = $config->{libraries};
        $notification->{http}  = HTTP::Tiny->new(agent => q[PlexScan/1.0]);
      }
      else
      {
        warn fairu::message::get(plex_url_not_valid => $config->{webhookUrl});
        $error++;
      }
    }
    else
    {
      warn fairu::message::get(q[plex_conf_not_valid]);
      $error++;
    }
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

      warn fairu::message::get(plex_no_scan => $dir, $url, $res->{status}, $res->{reason})
        unless ($res->{success});
    }
  }
  else
  {
    warn fairu::message::get(plex_mode_not_valid => $mode);
  }
}


__PACKAGE__
