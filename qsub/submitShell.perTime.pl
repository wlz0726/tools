#!/usr/bin/perl -w
use strict;
use warnings;
# generate by wanglizhong@genomics.cn

my $in=shift;
my $time=shift;
die "perl $0 test.sh  sleep_time(30s or 30m or 1h)\n"unless $time;

my $count=0;
open(I,"$in");
while(<I>){
    chomp;
    $count++;
    `$_`;
    my $date=`date`;
    print "Submitted $count jobs at $date";
    `sleep $time`;
}
my $date2=`date`;
print "Done...Total submitted $count jobs.\n$date2\n";
