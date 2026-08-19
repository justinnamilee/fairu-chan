#!/usr/bin/perl

package fairu::chan::message::english;

use strict;


my %message =
(
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
  message_language       => qq[Unable to load language: %s\n],
  message_key            => qq[Unknown language message key: %s: %s\n]
);


sub interface() { sub { $message{shift()} } }
sub name()      { q[English] }


__PACKAGE__
