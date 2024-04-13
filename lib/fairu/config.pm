#!/usr/bin/perl
package fairu::config;


use strict;
use lib q[lib];

use YAML;
use fairu::notification;
use Exporter q[import];
our @EXPORT_OK = qw[meta data];


###
# constants

sub DEF_MODE() { q[copy] }


###
# storage for my stuff

my $config = undef;


###
# stoopid wrappers

sub meta() { ref($config) ? $config->{meta} : {} }
sub data() { ref($config) ? $config->{data} : {} }


###
# parse & validation

sub yaml2bool(_)
{
  # no need for fc() if you stick to ascii
  return (lc($_[0]) eq q[true] || $_[0] == 1);
}

sub validateGrouping($$)
{
  my ($error, $title, $group) = (0, @_);

  #* required options for a group
  unless (ref($group) eq 'HASH')
  {
    warn qq[Failed to validate config($title): grouping should be a hash];
    $error++;
  }

  unless (ref($group->{inFile}) eq q[HASH] && ref($group->{outFile}) eq q[HASH])
  {
    warn qq[Failed to validate config($title): inFile and outFile should be hashes\n];
    $error++;
  }

  unless (-d $group->{inFile}->{basePath})
  {
    warn qq[Failed to validate config($title): inFile->basePath '$group->{inFile}->{basePath}' is not a directory\n];
    $error++;
  }

  unless ((! -e $group->{outFile}->{basePath}) || -d $group->{outFile}->{basePath})
  {
    warn qq[Failed to validate config($title): outFile->basePath '$group->{outFile}->{basePath}' is not a directory\n];
    $error++;
  }

  unless (length($group->{inFile}->{inRegex}) > 0)
  {
    warn qq[Failed to validate config($title): inFile->inRegex should be a string of length > 0\n];
    $error++;
  }

  unless (length($group->{outFile}->{outSprintf}) > 0)
  {
    warn qq[Failed to validate config($title): outFile->outSprintf should be a string of length > 0\n];
    $error++;
  }

  #* optional... options for a group
  $group->{fileMode} = DEF_MODE unless (defined($group->{fileMode}));
  $group->{fileMode} = lc($group->{fileMode});

  unless ($group->{fileMode} eq q[move] || $group->{fileMode} eq q[copy])
  {
    warn qq[Failed to validate config($title): fileMode should be 'copy' or 'move'\n];
    $error++;
  }

  if (defined($group->{inFile}->{recurse}))
  {
    $group->{inFile}->{recurse} = yaml2bool($group->{inFile}->{recurse});
  }

  if (defined($group->{mapFunction}))
  {
    if (ref($group->{mapFunction}) eq q[HASH])
    {
      foreach my $map (keys(%{$group->{mapFunction}}))
      {
        #? try to compile the local mappings, these override global mappings if conflicting
        $group->{mapFunction}->{$map} = eval $group->{mapFunction}->{$map};

        if ($@ || ref($group->{mapFunction}->{$map}) ne q[CODE])
        {
          warn qq[Failed to validate config($title): mapFunction->$map should be a string containing a valid perlsub];
          $error++
        }
      }
    }
    else
    {
      warn qq[Failed to validate config($title): outFile->mapFunction should be a hash containing perlsubs\n];
      $error++;
    }
  }

  return ($error);
}

sub validateMeta($)
{
  my ($error, $meta) = (0, @_);

  #* optional... options for meta
  if (defined($meta->{autoreload}))
  {
    $meta->{autoreload} = yaml2bool($meta->{autoreload});
  }

  if (defined($meta->{recurse}))
  {
    $meta->{recurse} = yaml2bool($meta->{recurse});
  }

  if (defined($meta->{notification}))
  {
    if (ref($meta->{notification}) eq q[HASH])
    {
      unless (fairu::notification::init($meta->{notification}) == 0)
      {
        warn qq[Failed to setup notifications: ¯\\_(ツ)_/¯\n];
        $error++;
      }
    }
    else
    {
      warn qq[Failed to setup notifications: meta->notification should be a HASH\n];
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
        $meta->{mapFunction}->{$map} = eval $meta->{mapFunction}->{$map};

        if ($@ || ref($meta->{mapFunction}->{$map} ne q[CODE]))
        {
          warn qq[Failed to validate config: mapFunction->$map should be a string containing a valid perlsub\n];
          $error++;
        }
      }
    }
    else
    {
      warn qq[Failed to validate config: mapFunction should be a hash containing perlsubs\n];
      $error++;
    }
  }

  if (defined($meta->{idleTime}))
  {
    unless ($meta->{idleTime} >= 0)
    {
      warn qq[Failed to validate config: idleTime should be greater than or equal to zero\n];
      $error++;
    }
  }

  if (defined($meta->{waitTime}))
  {
    unless ($meta->{waitTime} >= 0)
    {
      warn qq[Failed to validate config: waitTime should be greater than or equal to zero\n];
      $error++;
    }
  }

  return ($error);
}

sub validateData($)
{
  my ($error, $data) = (0, @_);

  foreach my $title (sort keys(%{$data}))
  {
    unless ((my $count = validateGrouping($title, $data->{$title})) == 0)
    {
      warn qq[Failed to validate config($title): $count problem], $count > 1 ? q[s] : (), qq[ found\n];
      $error++;
    }
  }

  return ($error)
}

sub parse($)
{
  my ($error, $newConfig, $file) = (0, undef, @_);

  if (-f $file && -r $file)
  {
    eval { $newConfig = YAML::LoadFile($file) };

    if ($@)
    {
      warn qq[Failed to parse config: $file should be a valid YAML file\n];
      $error++;
    }
    else
    {
      # should probably warn about these next two lines... probably
      $newConfig->{meta} = {} unless (ref($newConfig->{meta}) eq q[HASH]);
      $newConfig->{data} = {} unless (ref($newConfig->{data}) eq q[HASH]);

      # validate the two sections required for operation
      $error++ unless (validateMeta($newConfig->{meta}) == 0);
      $error++ unless (validateData($newConfig->{data}) == 0);
    }
  }
  else
  {
    warn qq[Failed to parse config: input should be a readable file\n];
    $error++;
  }

  if ($error == 0)
  {
    $config = $newConfig;
    print qq[Config loaded...\n];
  }
  elsif (defined($config))
  {
    warn qq[Keeping old config...\n];
  }
  else
  {
    warn qq[Problems found in config, aborting...\n];
  }

  return ($error);
}


__PACKAGE__
