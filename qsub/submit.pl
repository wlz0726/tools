#!/usr/bin/perl 
use strict;
use warnings;


my $dir=shift;
die "$0 z.dir\n"unless $dir;

`for i in $dir/*pbs; do qsub \$i;done`;
