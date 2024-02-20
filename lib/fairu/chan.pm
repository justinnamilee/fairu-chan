#!/usr/bin/perl

package fairu::chan;


use strict;
use lib q[lib];


use fairu::config qw[meta data];
use fairu::notification q[notify];
use File::Spec;
use File::Copy;
use File::Path;
use Exporter q[import];
our @EXPORT_OK = qw[uwu];


sub scanFiles($$)
{
  my ($recurse, $path, @f) = @_;

  if (opendir(my $d, $path))
  {
    @f = map { ($recurse && -d) ? scanFiles($recurse, $_) : $_ } map { File::Spec->join($path, $_) } grep { !/^\.\.?$/ } readdir($d);
  }
  else
  {
    warn qq[Unabled to open path: $path\n];
  }

  return (@f);
}

sub getFiles()
{
  my $cache = {};

  foreach my $title (keys(%{data()}))
  {
    my $path = data->{$title}->{inFile}->{basePath};

    unless (exists($cache->{$path}))
    {
      $cache->{$path} = [scanFiles((meta->{recurse} || data->{$title}->{inFile}->{recurse}), $path)];
    }
  }

  return ($cache);
}

sub matchFiles($)
{
  my ($map, $cache) = ({}, @_);

  foreach my $title (keys(%{data()}))
  {
    my $group = data->{$title};
    my $match = qr[$group->{inFile}->{inRegex}];

    foreach my $file (@{$cache->{$group->{inFile}->{basePath}}})
    {
      #? volume (barf), directory, file
      my ($v, $d, $f) = File::Spec->splitpath($file);

      if ($f =~ $match)
      {
        #? get the output file name
        my $out = File::Spec->join
        (
          $group->{outFile}->{basePath},
          sprintf(
            $group->{outFile}->{outSprintf},
            #? build the insertion list for the sprintf from named matches (%+)
            map
            {
              exists($group->{mapFunction}->{$_})

                #? apply a "local" mapping function if it exists
                ? $group->{mapFunction}->{$_}->($+{$_})
                
                #? if not, try a "global" mapping function, otherwise return the raw data
                : (exists(meta->{mapFunction}->{$_}) ? meta->{mapFunction}->{$_}->($+{$_}) : $+{$_})

            #? from the %+ we take data in lexical order (https://perldoc.perl.org/functions/sort) 
            } sort keys(%+)
          )
        );

        $map->{$file} = {mode => $group->{fileMode}, file => $out} unless (-e $out);
      }
    }
  }

  return ($map);
}

sub uwu($)
{
  my ($error, $action) = (0, @_);
  
  my $cache = getFiles();
  my $map = matchFiles($cache);

  foreach my $k (keys(%{$map}))
  {
    my ($mode, $j) = ($map->{$k}->{mode}, $map->{$k}->{file});

    print qq['$k' -> '$j'\n];

    my ($v, $d, $f) = File::Spec->splitpath($j);
    my $path = File::Spec->join($v, $d);

    if ($action && ! -d $path)
    {
      unless (File::Path->make_path($path))
      {
        warn qq[Failed to create path: $path\n];
        $error++;
      }
    }

    if ($action && -d $path)
    {
      if (($mode eq q[move] && move($k, $j)) || ($mode eq q[copy] && copy($k, $j)))
      {
        notify($f); # tell the whole world above it, if we're supposed to
      }
      else
      {
        warn qq[Failed to $mode '$k' to '$j': $!\n];
        $error++;
      }
    }
  }

  return ($error);
}


__PACKAGE__