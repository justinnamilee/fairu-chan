#!/usr/bin/perl
package fairu::config;


use strict;
use lib q[lib];

use YAML::PP;
use fairu::chan::message;
use fairu::chan::default;
use fairu::notification;

use Exporter q[import];
our @EXPORT_OK = qw[meta data];


###
# storage for my stuff

my $config = undef;


###
# stoopid wrappers

sub meta() { ref($config) ? $config->{meta} : {} }
sub data() { ref($config) ? $config->{data} : {} }


###
# parse & validation

sub validateGrouping($$)
{
  my ($title, $group) = @_;
  my $error = 0;

  #* required options for a group
  unless (ref($group) eq 'HASH')
  {
    warn fairu::chan::message::get(conf_group => $title);
    $error++;
  }

  unless (ref($group->{inFile}) eq q[HASH] && ref($group->{outFile}) eq q[HASH])
  {
    warn fairu::chan::message::get(conf_group_in_out => $title);
    $error++;
  }

  unless (-d $group->{inFile}->{basePath})
  {
    warn fairu::chan::message::get(conf_group_in_base => $title, $group->{inFile}->{basePath});
    $error++;
  }

  unless ((! -e $group->{outFile}->{basePath}) || -d $group->{outFile}->{basePath})
  {
    warn fairu::chan::message::get(conf_group_out_base => $title, $group->{outFile}->{basePath});
    $error++;
  }

  unless (length($group->{inFile}->{inRegex}) > 0)
  {
    warn fairu::chan::message::get(conf_group_in_regex => $title);
    $error++;
  }

  unless (length($group->{outFile}->{outSprintf}) > 0)
  {
    warn fairu::chan::message::get(conf_group_out_sprintf => $title);
    $error++;
  }

  #* optional... options for a group
  $group->{fileMode} = fairu::chan::default->ACTION
    unless (defined($group->{fileMode}));
  $group->{fileMode} = lc($group->{fileMode});

  unless ($group->{fileMode} eq q[move] || $group->{fileMode} eq q[copy])
  {
    warn fairu::chan::message::get(conf_group_file_mode => $title);
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
          warn fairu::chan::message::get(conf_group_map_item => $title, $map);
          $error++
        }
      }
    }
    else
    {
      warn fairu::chan::message::get(conf_group_map => $title);
      $error++;
    }
  }

  return ($error);
}

sub validateMeta($)
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
        warn fairu::chan::message::get(q[conf_meta_notif_init]);
        $error++;
      }
    }
    else
    {
      warn fairu::chan::message::get(q[conf_meta_notif_hash]);
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
          warn fairu::chan::message::get(conf_meta_map_item => $map);
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
      warn fairu::chan::message::get(q[conf_meta_idle]);
      $error++;
    }
  }

  if (defined($meta->{waitTime}))
  {
    unless ($meta->{waitTime} >= 0)
    {
      warn fairu::chan::message::get(q[conf_meta_wait]);
      $error++;
    }
  }

  return ($error);
}

sub validateData($)
{
  my $data = @_;
  my $error = 0;

  foreach my $title (sort keys(%{$data}))
  {
    unless ((my $count = validateGrouping($title, $data->{$title})) == 0)
    {
      warn fairu::chan::message::get(conf_data => $title, $count);
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
    eval { $newConfig = YAML::PP::LoadFile($path) };

    if ($@)
    {
      warn fairu::chan::message::get(conf_parse_loadfile => $path);
      $error++;
    }
    else
    {
      $newConfig->{meta} = {} unless (ref($newConfig->{meta}) eq q[HASH]);
      $newConfig->{data} = {} unless (ref($newConfig->{data}) eq q[HASH]);

      # validate the two sections required for operation
      $error++ unless (validateMeta($newConfig->{meta}) == 0);
      $error++ unless (validateData($newConfig->{data}) == 0);
    }
  }
  else
  {
    warn fairu::chan::message::get(conf_parse_not_valid => $path);
    $error++;
  }

  if ($error == 0)
  {
    $config = $newConfig;
    warn fairu::chan::message::get(q[conf_reload]);

    fairu::notification::send(q[information], q[Config loaded...]);
  }
  elsif (defined($config))
  {
    warn fairu::chan::message::get(q[conf_no_reload]);
  }
  else
  {
    warn fairu::chan::message::get(q[conf_no_config]);
  }

  return ($error);
}


__PACKAGE__
