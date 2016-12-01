#!/usr/bin/perl -w
use strict;
use warnings;
# generate by wanglizhong@genomics.cn

my $dir=shift;
my $time=shift;
die "perl $0 pbs.dir.name  sleep_time(30s or 30m or 1h)\n"unless $time;
my $round=0;
my $count=0;
my @pbs=<$dir/*pbs>;
for(my $i=0;$i<@pbs;$i++){
    $round++;
    for(my $j=1;$j<=100;$j++){
	if($i<@pbs){
	    `qsub $pbs[$i]`;
	    $i++;
	    $count++;
	}else{
	    last;
	}
    }
    $i--;
    my $date=`date`;
    print "Round...$round, submitted $count jobs at $date";
    
    if($i+1<@pbs){
	`sleep $time`;
    }
}
my $date2=`date`;
print "Done...Total submitted $count jobs.\n$date2\n";
