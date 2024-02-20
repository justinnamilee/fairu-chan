#!/usr/bin/perl

package fairu::notification;


use strict;
use lib q[lib];


use fairu::notification::discord;
use Exporter q[import];
our @EXPORT_OK = qw[notify];


my $notification = [];


sub init($)
{
  my ($error, $config) = (0, @_);

  if (ref($config) eq q[HASH])
  {
    if (exists($config->{discord}))
    {
      if (fairu::notification::discord::init($config->{discord}) == 0)
      {
        push(@{$notification}, fairu::notification::discord->handler);
      }
      else
      {
        $error++;
      }

      #TODO add more notification types here
    }
  }
  elsif (defined($config))
  {
    warn qq[Couldn't configure notifications: meta->notification should be a HASH\n];
    $error++;
  }

  return ($error);
}

sub notify(@)
{
  #? we'll YOLO these notifications with eval for now, no need to crash
  eval { $_->(@_) for @{$notification} };
  warn qq[Ran into notification sending issues.\n] if ($@);
}


__PACKAGE__
