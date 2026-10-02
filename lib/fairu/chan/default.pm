#!/usr/bin/perl
package fairu::chan::default;

use strict;


sub ACTION() { q[copy] }
sub IDLE()   { 600 }
sub WAIT()   { 5 }



__PACKAGE__