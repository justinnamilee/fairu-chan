#!/usr/bin/perl

package fairu::chan;


use strict;
use fairu::config qw[meta data];
use fairu::message;
use fairu::notification;
use File::Spec;
use File::Copy;
use File::Path;


#* globals *#

my $run = 1;


#* private functions *#

sub _recursive($)
{
  meta->{recurse} || data->{shift()}->{inFile}->{recurse}
    ? 1
    : 0
}

sub _scan($$);
sub _scan($$)
{
  my ($path, $recurse) = @_;
  my @f = ();

  if (-f $path)
  {
    push(@f, $path);
  }
  elsif (-d $path && opendir(my $dh, $path))
  {
    foreach my $i (grep { !/^\.\.?$/ } readdir($dh))
    {
      my $p = File::Spec->join($path, $i);

      next
        if -l $p && !meta->{followSymlinks};

      push(@f, -f $p ? $p : (-d $p && $recurse ? _scan($p, $recurse) : ()))
    }
  }
  else
  {
    warn fairu::message::get(chan_open => $path, $! // q[N/A]);
  }

  return (@f);
}

sub _find()
{
  my $cache = {0 => {}, 1 => {}}; # quick hack fix

  foreach my $title (keys(%{data()}))
  {
    my $path = data->{$title}->{inFile}->{basePath};

    unless (exists($cache->{_recursive($title)}->{$path}))
    {
      $cache->{_recursive($title)}->{$path} = [_scan($path, _recursive($title))];
    }
  }

  return ($cache);
}

sub _match($)
{
  my ($cache) = @_;
  my $map = {};

  foreach my $title (keys(%{data()}))
  {
    my $group = data->{$title};

    foreach my $file (@{$cache->{_recursive($title)}->{$group->{inFile}->{basePath}}})
    {
      #? volume (barf), directory, file
      my ($v, $d, $f) = File::Spec->splitpath($file);

      if ($f =~ $group->{inFile}->{inRegex})
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


#* public functions *#

sub stop()
{
  $run = 0;
}

sub uwu($)
{
  my ($action) = @_;
  my ($error, $count) = (0, 0);

  my $map = _match(_find());

  foreach my $ifile (keys(%{$map}))
  {
    last unless $run; # if exit signal caught we need to stop

    my ($mode, $ofile) = ($map->{$ifile}->{mode}, $map->{$ifile}->{file});

    if (length($ofile) && ! -e $ofile)
    {
      my ($v, $d, $f) = File::Spec->splitpath($ofile);
      my $path = File::Spec->join($v, $d);

      if ($action && length($path) && ! -d $path)
      {
        unless (File::Path::make_path($path))
        {
          warn fairu::message::get(chan_build => $path);
          $error++;
        }
      }

      if ($action && -d $path)
      {
        if (($mode eq q[move] && move($ifile, $ofile)) || ($mode eq q[copy] && copy($ifile, $ofile)))
        {
          fairu::notification::send(q[event], $ofile);
          $count++
        }
        else
        {
          warn fairu::message::get(chan_action => $mode, $ifile, $ofile, $!);
          $error++;
        }
      }

      print fairu::message::get(chan_success => $mode, $ifile, $ofile);
    }
  }

  fairu::notification::send(q[debug], fairu::message::get(chan_notif_debug => int(keys(%{$map})), $count)) if $count > 0;

  return ($error);
}


__PACKAGE__
