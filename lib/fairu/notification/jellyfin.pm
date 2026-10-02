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

sub _find {
  my ($self, $path) = @_;

  my @i = ();
  my $term = q[]; #!! convert path to term

  my $res = HTTP::Tiny->new(agent => $self->{agent})->get(
    sprintf(
      $self->{path}->{find},
      $self->{url},
      $self->{type},
      URI::Escape::uri_escape_utf8($term),
    ),
    {
      headers => {
        Authorization => qq[MediaBrowser Token="$self->{token}"],
      },
    }
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
    #!! JSON decode failed
  }

  return (@i);
}

sub _full
{
  my ($self) = @_;

  if ($self->_running)
  {
    #!! WARN ALREADY RUNNING
  }
  else
  {
    warn fairu::message::get(q[jelly_full]);

    my $res = HTTP::Tiny->new(agent => $self->{agent})->post(
      sprintf($self->{path}->{full}, $self->{url}),
      {
        headers => {
          Authorization => qq[MediaBrowser Token="$self->{token}"],
        },
      }
    );
  }
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
}

sub _running
{
  my ($self) = @_;

  my $ret = 1; #? assume its running

  my $res = HTTP::Tiny->new(agent => $self->{agent})->post(
    sprintf($self->{path}->{full}, $self->{url}),
    {
      headers => {
        Authorization => qq[MediaBrowser Token="$self->{token}"],
      },
    }
  );

  if ($res->{status} == 200 && length($res->{content}))
  {
    if (my $j = eval { JSON::PP::decode_json($res->{content}) })
    {
      my ($m) = grep { $_->{Key} eq q[RefreshLibrary] } @{$j};

      if (ref($m) eq q[HASH] && ref($m->{LastExecutionResult}) eq q[HASH])
      {
        $ret = $m->{LastExecutionResult}->{Status} ne q[Completed];
      }
      #!! bad struct
    }
    #!! bad json
  }
  #!! bad result

  return ($ret);
}

sub _scan
{
  my ($self, $id) = @_;

  defined($id) ? $self->_partial($id) : $self->_full
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
        $notification->{token} = $config->{token};
        $notification->{type} = $config->{type} // DEF_TYPE;
        $notification->{url} = $config->{url};
      }
      #!! ELSE URL NOT VALID
    }
    #!! ELSE CONFIG NOT HASH
  }

  return ($error > 0 ? $error : bless $notification, $self);
}

sub handler
{
  my ($self, $mode, $path) = @_;

  if ($mode eq q[event])
  {
    foreach my $i ($self->_find($path))
    {
      $self->_scan($i)
    }
  }
  #!! ELSE MODE NOT SUPPORTED
}


__PACKAGE__
