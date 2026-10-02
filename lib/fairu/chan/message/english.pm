#!/usr/bin/perl

package fairu::chan::message::english;

use strict;


my %message =
(
  chan_action            => qq[Failed to %s '%s' to '%s': %s\n],
  chan_build             => qq[Failed to create path: %s\n],
  chan_open              => qq[Failed to open directory for reading: %s\n],
  chan_notif_debug       => qq[Matched files: %d, Processed files: %d\n],
  chan_success           => qq[%s: '%s' -> '%s'\n],
  conf_data              => qq[Failed to validate config(%s): group parse terminate with errors: %d\n],
  conf_group             => qq[Failed to validate config(%s): grouping should be a hash\n],
  conf_group_file_mode   => qq[Failed to validate config(%s): fileMode should be 'copy' or 'move'\n],
  conf_group_in_base     => qq[Failed to validate config(%s): inFile->basePath '%s' is not a directory\n],
  conf_group_in_out      => qq[Failed to validate config(%s): inFile and outFile should be hashes\n],
  conf_group_in_regex    => qq[Failed to validate config(%s): inFile->inRegex should be a string of length > 0\n],
  conf_group_map         => qq[Failed to validate config(%s): outFile->mapFunction should be a hash containing perlsubs\n],
  conf_group_map_item    => qq[Failed to validate config(%s): mapFunction->%s should be a string containing a valid perlsub],
  conf_group_out_base    => qq[Failed to validate config(%s): outFile->basePath '%s' is not a directory\n],
  conf_group_out_sprintf => qq[Failed to validate config(%s): outFile->outSprintf should be a string of length > 0\n],
  conf_meta_idle         => qq[Failed to validate config(meta): idleTime should be greater than or equal to zero\n],
  conf_meta_map          => qq[Failed to validate config(meta): mapFunction should be a hash containing perlsubs\n],
  conf_meta_map_item     => qq[Failed to validate config(meta): mapFunction->%s should be a string containing a valid perlsub\n],
  conf_meta_notif_init   => qq[Failed to validate config(meta): Failed to parse notification section\n],
  conf_meta_notif_hash   => qq[Failed to validate config(meta): meta->notification should be a HASH\n],
  conf_meta_wait         => qq[Failed to validate config(meta): waitTime should be greater than or equal to zero\n],
  conf_no_config         => qq[Failed to load config, aborting...\n],
  conf_no_reload         => qq[Keeping old config...\n],
  conf_parse_loadfile    => qq[Failed to parse config: '%s' should be a valid YAML file\n],
  conf_parse_not_valid   => qq[Failed to parse config: '%s' is not a readable file or directory\n],
  conf_reload            => qq[Config loaded...\n],
  discord_conf_not_valid => qq[Couldn't configure Discord: config should be a HASH and template should be non-zero length string\n],
  discord_no_get         => qq[Couldn't GET on Discord webhook.\n],
  discord_url_not_valid  => qq[Couldn't configure Discord: '%s' should be a valid HTTPS URL\n],
  message_language       => qq[Unable to load language: %s\n],
  message_key            => qq[Unknown language message key: %s: %s\n],
  notif_conf_failed      => qq[Couldn't configure notification(%s)],
  notif_conf_not_valid   => qq[Couldn't configure notifications: meta->notification should be a HASH\n],
  notif_mode_not_valid   => qq[Unknown notification type '%s'.\n],
  notif_send_failed      => qq[Issues sending notification(s).\n],
  plex_conf_not_valid    => qq[Couldn't configure Plex: config must be a HASH with keys 'webhookUrl', 'webhookToken', and 'libraries'\n],
  plex_mode_not_valid    => qq[Unsupported mode '%s' for Plex Scanner Notification\n],
  plex_no_scan           => qq[Couldn't scan '%s': %s => %s(%s)\n],
  plex_url_not_valid     => qq[Couldn't configure Plex: '%s' should be a valid HTTP or HTTPS URL\n]
);


sub interface() { sub { $message{shift()} } }
sub name()      { q[English] }


__PACKAGE__
