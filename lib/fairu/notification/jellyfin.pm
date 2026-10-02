#!/usr/bin/perl

package fairu::notification::jellyfin;

use strict;
use fairu::message;
use File::Basename;
use File::Spec;


sub DEF_URL_FIND() {}
sub DEF_URL_FULL() {}
sub DEF_URL_SCAN() {}


my $loaded = undef;


#* internal stuff *#
sub _load()
{
  my $error = 0;

  if (!$loaded)
  {
    $error++ && warn q[Data::Validate::URI]
      unless eval { require Data::Validate::URI };
    $error++ && warn q[HTTP::Tiny]
      unless eval { require HTTP::Tiny };
    $error++ && warn q[JSON::PP]
      unless eval { require JSON::PP };
    $error++ && warn q[URI::Escape]
      unless eval { require URI::Escape };
  }

  return $error;
}


sub new($)
{
  my ($error, $notification, $self, $config) = (0, {}, @_);

  if (ref($config) eq q[HASH] && length($config->{url}) && length($config->{token}))
  {
    unless (eval {
      require HTTP::Tiny; require URI::Escape;
      require Data::Validate::URI; require JSON::PP
    })
    {
      warn qq[crap\n];
      $error++;
    }

    if (!$error && Data::Validate::URI::is_http_uri($config->{url}))
    {

    }
  }
}


__PACKAGE__
