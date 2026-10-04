#!/usr/bin/perl

package fairu::notification::jellyfin;

use strict;
use fairu::message;
use File::Basename;


#* statics *#

sub DEF_AGNT() { q[JellyScan/1.0] }
sub DEF_FIND() { q[%s/Items?IncludeItemTypes=%s&Fields=Path&Limit=20&SearchTerm=%s] }
sub DEF_FULL() { q[%s/Library/Refresh] }
sub DEF_SCAN() { q[%s/Items/%s/Refresh?Recursive=true&MetadataRefreshMode=Default&ImageRefreshMode=Default] }
sub DEF_TASK() { q[%s/ScheduledTasks] }
sub DEF_TYPE() { q[Series,Movie] }


#* globals *#

my $loaded = undef;


#* internal stuff *#

sub _clean
{
  my ($self, $path) = @_;

  $path =~ s/_/ /g;
  $path =~ s/\s*\[[^]]+\]\s*//g;
  #? more as needed?

  return ($path);
}

sub _find
{
  my ($self, $path) = @_;

  my @i = ();
  my $term = $self->_clean($path);

  my $res = HTTP::Tiny->new(agent => $self->{agent})->get(
    sprintf(
      $self->{path}->{find},
      $self->{url},
      $self->{type},
      URI::Escape::uri_escape_utf8($term),
    ),
    { headers => { Authorization => $self->{token} } }
  );

  if ($res->{status} == 200 && length($res->{content}))
  {
    if (my $j = eval { JSON::PP::decode_json($res->{content}) })
    {
      if (ref($j->{Items}) eq q[ARRAY]) {
        @i = map {
          [@{$_}{qw(Name Id Path)}]
        } grep { ($_->{Path} // '') =~ /^\Q$path\E(?:\/|$)/ } @{$j->{Items}}
      }
    }
    else
    {
      warn fairu::message::get(jelly_json_failed => q[search]);
    }
  }

  return (@i);
}

sub _full
{
  my ($self) = @_;

  warn fairu::message::get(q[jelly_full]);

  return ($self->_post(sprintf($self->{path}->{full}, $self->{url})));
}

sub _load
{
  my $error = 0;

  if (!$loaded)
  {
    ++$error && warn fairu::message::get(generic_require_failed => q[Data::Validate::URI])
      unless eval { require Data::Validate::URI };

    ++$error && warn fairu::message::get(generic_require_failed => q[HTTP::Tiny])
      unless eval { require HTTP::Tiny };

    ++$error && warn fairu::message::get(generic_require_failed => q[JSON::PP])
      unless eval { require JSON::PP };

    ++$error && warn fairu::message::get(generic_require_failed => q[URI::Escape])
      unless eval { require URI::Escape };
  }

  return $error;
}

sub _partial
{
  my ($self, $id) = @_;

  return ($self->_post(sprintf($self->{path}->{scan}, $self->{url}, $id)));
}

sub _post
{
  my ($self, $url) = @_;

  my $state = $self->_success(
    HTTP::Tiny->new(agent => $self->{agent})->post(
      $url, { headers => { Authorization => $self->{token} } }
    )->{status}
  );

  warn fairu::message::get(jelly_http_failed => $url)
    unless $state;

  return ($state);
}

sub _success
{
  my ($self, $code) = @_;

  return ($code == 200 || $code == 204);
}


#* public methods *#

sub new
{
  my ($self, $config) = @_;

  my ($notification, $error) = ({}, $self->_load);

  unless ($error)
  {
    if (ref($config) eq q[HASH] && length($config->{url}) && length($config->{token}))
    {
      if (Data::Validate::URI::is_web_uri($config->{url}))
      {
        $notification->{agent} = $config->{agent} // DEF_AGNT;
        $notification->{path} = {};
        $notification->{path}->{find} = $config->{path}->{find} // DEF_FIND;
        $notification->{path}->{full} = $config->{path}->{full} // DEF_FULL;
        $notification->{path}->{scan} = $config->{path}->{scan} // DEF_SCAN;
        $notification->{path}->{task} = $config->{path}->{task} // DEF_TASK;
        $notification->{token} = qq[MediaBrowser Token="$config->{token}"];
        $notification->{type} = $config->{type} // DEF_TYPE;
        $notification->{url} = $config->{url};
      }
      else
      {
        warn fairu::message::get(q[jelly_url_not_valid]);
      }
    }
    else
    {
      warn fairu::message::get(q[jelly_conf_not_valid]);
    }
  }

  return ($error > 0 ? $error : bless $notification, $self);
}

sub handler
{
  my ($self, $mode, $path) = @_;

  if ($mode eq q[event])
  {
    if (my @id = $self->_find($path))
    {
      $self->_partial($_)
        foreach @id;
    }
    else
    {
      $self->_full
    }
  }
}


__PACKAGE__
