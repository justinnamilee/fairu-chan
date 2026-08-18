#!/usr/bin/perl

package fairu::chan::message::english;

use strict;


my %message =
(
  bad_message_language => qq[FATAL: Unable to load language: %s\n],
  bad_message_key => qq[FATAL: Unknown message key: %s: %s\n]
);


sub interface() { sub { $message{shift()} } }
sub name()      { q[English] }


__PACKAGE__
