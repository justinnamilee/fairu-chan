#!/usr/bin/perl

package fairu::notification::discord;


use strict;
use fairu::message;
use File::Basename;


# * globals *#

my $loaded = undef;


#* internal stuffz *#

sub _load
{
  my $error = 0;

  if (!$loaded)
  {
    ++$error && warn fairu::message::get(generic_require_failed => q[Data::Validate::URI])
      unless eval { require Data::Validate::URI };

    ++$error && warn fairu::message::get(generic_require_failed => q[WebService::Discord::Webhook])
      unless eval { require WebService::Discord::Webhook };

    $loaded = __PACKAGE__;
  }

  return ($error);
}


#* public methods *#

sub new($)
{
  my ($self, $config) = @_;
  my ($notification, $error) = ({ hook => undef, template => undef }, $self->_load);

  unless ($error)
  {
    if (ref($config) eq q[HASH] && length($config->{template}) && length($config->{webhookUrl}))
    {

      $notification->{template} = $config->{template};

      if (Data::Validate::URI::is_https_uri($config->{webhookUrl}))
      {
        my $d = WebService::Discord::Webhook->new(url => $config->{webhookUrl}, verify_SSL => 1);

        #? do a connection test / get the webhook thingie
        if (eval { $d->get })
        {
          $notification->{hook} = $d;
        }
        else
        {
          warn fairu::message::get(q[discord_no_get]);
          $error++;
        }
      }
      else
      {
        warn fairu::message::get(discord_url_not_valid => $config->{webhookUrl});
        $error++;
      }
    }
    else
    {
      warn fairu::message::get(q[discord_conf_not_valid]);
      $error++;
    }
  }

  return ($error > 0 ? $error : (bless $notification, $self));
}

sub handler(@)
{
  my ($self, $mode, @data) = @_;

  if ($mode eq 'event')
  {
    $self->{hook}->execute(sprintf($self->{template}, (File::Basename::fileparse($data[0]))[0]));
  }
  else
  {
    $self->{hook}->execute(sprintf($self->{template}, @data));
  }

  return 1;
}


__PACKAGE__
