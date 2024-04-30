#!/usr/bin/perl

package fairu::chan;


use strict;
use lib q[lib];


use fairu::config qw[meta data];
use fairu::notification;
use File::Spec;
use File::Copy;
use File::Path;


sub recursive($)
{
  (meta->{recurse} || data->{$_[0]}->{inFile}->{recurse}) ? 1 : 0
}

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
  my $cache = {0 => {}, 1 => {}}; # quick hack fix

  foreach my $title (keys(%{data()}))
  {
    my $path = data->{$title}->{inFile}->{basePath};

    unless (exists($cache->{recursive($title)}->{$path}))
    {
      $cache->{recursive($title)}->{$path} = [scanFiles(recursive($title), $path)];
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

    foreach my $file (@{$cache->{recursive($title)}->{$group->{inFile}->{basePath}}})
    {
      #? volume (barf), directory, file
      my ($v, $d, $f) = File::Spec->splitpath($file);

      if ($f =~ $match)
      {
        #? check for match at lower precedence value (undef == +inf), skip this match if one is found found
        unless
        (
          # SKIP if there's already a match
          exists($map->{$file}) &&
          (
            # and this group has no precedence
            !defined($group->{precedence}) ||
            (
              # or there's a precendence on this existing match and our precedence is higher
              defined($map->{$file}->{precedence}) && $group->{precedence} >= $map->{$file}->{precedence}
            )
          )
        )
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

          $map->{$file} = {mode => $group->{fileMode}, file => $out, precedence => $group->{precedence}};
        }
      }
    }
  }

  return ($map);
}

sub uwu($)
{
  my ($error, $count, $action) = (0, 0, @_);

  my $cache = getFiles();
  my $map = matchFiles($cache);

  foreach my $ifile (keys(%{$map}))
  {
    my ($mode, $ofile) = ($map->{$ifile}->{mode}, $map->{$ifile}->{file});

    if (length($ofile) && ! -e $ofile)
    {
      my ($v, $d, $f) = File::Spec->splitpath($ofile);
      my $path = File::Spec->join($v, $d);

      if ($action && length($path) && ! -d $path)
      {
        unless (File::Path::make_path($path))
        {
          warn qq[Failed to create path: $path\n];
          $error++;
        }
      }

      if ($action && -d $path)
      {
        if (($mode eq q[move] && move($ifile, $ofile)) || ($mode eq q[copy] && copy($ifile, $ofile)))
        {
          fairu::notification::action($f);
          $count++
        }
        else
        {
          warn qq[Failed to $mode '$ifile' to '$ofile': $!\n];
          $error++;
        }
      }

      print qq[\u$mode: '$ifile' -> '$ofile'\n];
    }
  }

  fairu::notification::internal(sprintf(q[Matched %d files, processed %d files!], int(keys(%{$map})), $count)) if $count > 0;

  return ($error);
}


__PACKAGE__
