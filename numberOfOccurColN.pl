#! /usr/bin/perl
use strict;
use warnings;


my $file =shift;
my $colum=shift;
die "$0 <file> <col number you want to count>\n"unless $colum;
print "awk '{l[\$$colum]++}END{for (x in l) print x,l[x]}' $file\n";

