#!/usr/bin/perl

package fairu::message::english;

use strict;


#* global message structure *#

my %message =
(
  chan_action            => qq[Failed to %s '%s' to '%s': %s.\n],
  chan_build             => qq[Failed to create path: %s.\n],
  chan_open              => qq[Failed to open directory for reading: %s.\n],
  chan_notif_debug       => qq[Matched files: %d, processed files: %d.\n],
  chan_success           => qq[%s: '%s' -> '%s'\n],

  conf_data              => qq[Failed to validate config(%s): group parsing terminated with %d error(s).\n],
  conf_group             => qq[Failed to validate config(%s): group should be a HASH.\n],
  conf_group_file_mode   => qq[Failed to validate config(%s): fileMode should be 'copy' or 'move'.\n],
  conf_group_in_base     => qq[Failed to validate config(%s): inFile->basePath '%s' is not a directory.\n],
  conf_group_in_out      => qq[Failed to validate config(%s): inFile and outFile should be HASHes.\n],
  conf_group_in_regex    => qq[Failed to validate config(%s): inFile->inRegex should be a non-empty string.\n],
  conf_group_map         => qq[Failed to validate config(%s): outFile->mapFunction should be a HASH containing Perl subroutines.\n],
  conf_group_map_item    => qq[Failed to validate config(%s): mapFunction->%s should be a string containing a valid Perl subroutine.\n],
  conf_group_out_base    => qq[Failed to validate config(%s): outFile->basePath '%s' is not a directory.\n],
  conf_group_out_sprintf => qq[Failed to validate config(%s): outFile->outSprintf should be a non-empty string.\n],

  conf_meta_idle         => qq[Failed to validate config(meta): idleTime should be greater than or equal to zero.\n],
  conf_meta_map          => qq[Failed to validate config(meta): mapFunction should be a HASH containing Perl subroutines.\n],
  conf_meta_map_item     => qq[Failed to validate config(meta): mapFunction->%s should be a string containing a valid Perl subroutine.\n],
  conf_meta_notif_init   => qq[Failed to validate config(meta): failed to parse notification section.\n],
  conf_meta_notif_hash   => qq[Failed to validate config(meta): notification should be a HASH.\n],
  conf_meta_wait         => qq[Failed to validate config(meta): waitTime should be greater than or equal to zero.\n],

  conf_no_config         => qq[Failed to load config; aborting.\n],
  conf_no_reload         => qq[Keeping previous config.\n],
  conf_parse_loadfile    => qq[Failed to parse config: '%s' should be a valid YAML file.\n],
  conf_parse_not_valid   => qq[Failed to parse config: '%s' is not a readable file or directory.\n],
  conf_reload            => qq[Config loaded.\n],

  discord_conf_not_valid => qq[Failed to configure Discord: config should be a HASH and template should be a non-empty string.\n],
  discord_no_get         => qq[Failed to perform GET request to Discord webhook.\n],
  discord_url_not_valid  => qq[Failed to configure Discord: '%s' should be a valid HTTPS URL.\n],

  generic_require_failed => qq[Failed to import module: %s.\n],

  jelly_conf_not_valid   => qq[Failed to configure Jellyfin: config should be a HASH with keys 'url' and 'token'.\n],
  jelly_full             => qq[Falling back to full Jellyfin refresh.\n],
  jelly_full_running     => qq[Jellyfin reports that a full refresh is already in progress; skipping.\n],
  jelly_http_failed      => qq[Failed request for '%s'.\n],
  jelly_json_failed      => qq[Failed to decode response from '%s'.\n],
  jelly_json_not_valid   => qq[Jellyfin returned an unexpected JSON structure.\n],
  jelly_url_not_valid    => qq[Failed to configure Jellyfin: URL should contain a valid HTTP or HTTPS host.\n],

  message_language       => qq[Failed to load language: %s.\n],
  message_key            => qq[Unknown language message key: %s: %s.\n],

  notif_compile_failed   => qq[Failed to compile notification(%s).\n],
  notif_conf_failed      => qq[Failed to configure notification(%s).\n],
  notif_conf_not_valid   => qq[Failed to configure notifications: meta->notification should be a HASH.\n],
  notif_mode_not_valid   => qq[Unknown notification type '%s'.\n],
  notif_send_failed      => qq[Failed to send one or more notifications.\n],

  plex_conf_not_valid    => qq[Failed to configure Plex: config should be a HASH with keys 'webhookUrl', 'webhookToken', and 'libraries'.\n],
  plex_mode_not_valid    => qq[Unsupported mode '%s' for Plex scanner notification.\n],
  plex_no_scan           => qq[Failed to scan '%s': %s => %s(%s).\n],
  plex_url_not_valid     => qq[Failed to configure Plex: '%s' should be a valid HTTP or HTTPS URL.\n],

  script_bad_exec        => qq[Failed to execute '%s': %s.\n],
  script_conf_not_valid  => qq[Failed to configure script notification: config should be a HASH with key 'script'.\n],
  script_die_signal      => qq[Script '%s' terminated by signal %d.\n],
  script_die_status      => qq[Script '%s' exited with status %d.\n],
  script_no_exec         => qq[Failed to configure script notification: '%s' is not executable.\n]
);


#* public functions *#

sub interface() { sub { $message{shift()} } }
sub name()      { q[English] }


__PACKAGE__
