#!/usr/bin/perl -w

use strict;
use warnings;

my $dir=shift;
my $time=shift;
die "perl $0 z.pbs.dir.name  sleep_time(minute)\n\n"unless $time;
my @pbs=<$dir/*pbs>;
for(my $i=0;$i<@pbs;$i++){
    for(my $j=1;$j<=100;$j++){
	`qsub $pbs[$i]`;
	$i++
    }
    `sleep $time\\m`;
}
