#!/usr/bin/perl
package fairu::config;


use strict;
use YAML::PP;
use fairu::message;
use fairu::notification;
use Exporter q[import];
our @EXPORT_OK = qw[meta data];


###
# defaults

sub _default()
{{
  chan_fileMode  => q[copy],
  fairu_idleTime => 600,
  fairu_waitTime => 5
}}


###
# storage for my stuff

my $config = undef;


###
# stoopid wrappers

sub meta() { ref($config) ? $config->{meta} : {} }
sub data() { ref($config) ? $config->{data} : {} }


###
# parse & validation

sub _validate_grouping($$)
{
  my ($title, $group) = @_;
  my $error = 0;

  #* required options for a group
  unless (ref($group) eq q[HASH])
  {
    warn fairu::message::get(conf_group => $title);
    $error++;
  }

  unless (ref($group->{inFile}) eq q[HASH] && ref($group->{outFile}) eq q[HASH])
  {
    warn fairu::message::get(conf_group_in_out => $title);
    $error++;
  }

  unless (-d $group->{inFile}->{basePath})
  {
    warn fairu::message::get(conf_group_in_base => $title, $group->{inFile}->{basePath});
    $error++;
  }

  unless ((! -e $group->{outFile}->{basePath}) || -d $group->{outFile}->{basePath})
  {
    warn fairu::message::get(conf_group_out_base => $title, $group->{outFile}->{basePath});
    $error++;
  }

  unless (length($group->{inFile}->{inRegex}) > 0)
  {
    warn fairu::message::get(conf_group_in_regex => $title);
    $error++;
  }

  unless (length($group->{outFile}->{outSprintf}) > 0)
  {
    warn fairu::message::get(conf_group_out_sprintf => $title);
    $error++;
  }

  #* optional... options for a group
  $group->{fileMode} = _default->{chan_fileMode}
    unless (defined($group->{fileMode}));

  $group->{fileMode} = lc($group->{fileMode});

  unless ($group->{fileMode} eq q[move] || $group->{fileMode} eq q[copy])
  {
    warn fairu::message::get(conf_group_file_mode => $title);
    $error++;
  }

  if (defined($group->{mapFunction}))
  {
    if (ref($group->{mapFunction}) eq q[HASH])
    {
      foreach my $map (keys(%{$group->{mapFunction}}))
      {
        #? try to compile the local mappings, these override global mappings if conflicting
        $group->{mapFunction}->{$map} = eval qq[sub { $group->{mapFunction}->{$map} }];

        if ($@ || ref($group->{mapFunction}->{$map}) ne q[CODE])
        {
          warn fairu::message::get(conf_group_map_item => $title, $map);
          $error++
        }
      }
    }
    else
    {
      warn fairu::message::get(conf_group_map => $title);
      $error++;
    }
  }

  return ($error);
}

sub _validate_meta($)
{
  my ($meta) = @_;
  my $error = 0;

  #* optional... options for meta
  if (defined($meta->{notification}))
  {
    if (ref($meta->{notification}) eq q[HASH])
    {
      unless (fairu::notification::init($meta->{notification}) == 0)
      {
        warn fairu::message::get(q[conf_meta_notif_init]);
        $error++;
      }
    }
    else
    {
      warn fairu::message::get(q[conf_meta_notif_hash]);
      $error++;
    }
  }

  if (defined($meta->{mapFunction}))
  {
    if (ref($meta->{mapFunction}) eq q[HASH])
    {
      foreach my $map (keys(%{$meta->{mapFunction}}))
      {
        #? try to compile the global mappings
        $meta->{mapFunction}->{$map} = eval qq[sub { $meta->{mapFunction}->{$map} }];

        if ($@ || ref($meta->{mapFunction}->{$map} ne q[CODE]))
        {
          warn fairu::message::get(conf_meta_map_item => $map);
          $error++;
        }
      }
    }
    else
    {
      warn ;
      $error++;
    }
  }

  if (defined($meta->{idleTime}))
  {
    unless ($meta->{idleTime} >= 0)
    {
      warn fairu::message::get(q[conf_meta_idle]);
      $error++;
    }
  }
  else
  {
    $meta->{idleTime} = _default->{fairu_idleTime};
  }

  if (defined($meta->{waitTime}))
  {
    unless ($meta->{waitTime} >= 0)
    {
      warn fairu::message::get(q[conf_meta_wait]);
      $error++;
    }
  }
  else
  {
    $meta->{waitTime} = _default->{fairu_waitTime};
  }

  return ($error);
}

sub _validate_data($)
{
  my ($data) = @_;
  my $error = 0;

  foreach my $title (sort keys(%{$data}))
  {
    if (my $count = _validate_grouping($title, $data->{$title}))
    {
      warn fairu::message::get(conf_data => $title, $count);
      $error++;
    }
  }

  return ($error)
}

sub parse($)
{
  my ($path) = @_;
  my ($error, $newConfig) = (0, undef);

  if (-f $path && -r $path)
  {
    $newConfig = eval { YAML::PP::LoadFile($path) };

    if ($@)
    {
      warn fairu::message::get(conf_parse_loadfile => $path);
      $error++;
    }
    else
    {
      $newConfig->{meta} = {} unless (ref($newConfig->{meta}) eq q[HASH]);
      $newConfig->{data} = {} unless (ref($newConfig->{data}) eq q[HASH]);

      # validate the two sections required for operation
      $error++ unless (_validate_meta($newConfig->{meta}) == 0);
      $error++ unless (_validate_data($newConfig->{data}) == 0);
    }
  }
  else
  {
    warn fairu::message::get(conf_parse_not_valid => $path);
    $error++;
  }

  if ($error == 0)
  {
    $config = $newConfig;
    warn fairu::message::get(q[conf_reload]);

    fairu::notification::send(q[information], fairu::message::get(q[conf_reload]));
  }
  elsif (defined($config))
  {
    warn fairu::message::get(q[conf_no_reload]);
  }
  else
  {
    warn fairu::message::get(q[conf_no_config]);
  }

  return (!$error);
}


__PACKAGE__
