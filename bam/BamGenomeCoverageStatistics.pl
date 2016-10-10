#! /usr/bin/perl -w
use strict;
use warnings;

print "#ID\tCoveredSites\tSumDepth\n";
my $file=shift;
die "$0 bam\n"unless $file;
my $id;
if($file=~m/(\S+)\.bam$/){
    $id=$1;
}else{
    die "$file\n";
}
my $sites=0;
my $depth=0;
open(F,"/home/wanglizhong/bin/samtools depth $file |");
while(<F>){
    chomp;
    next if(/^\s*$/);
    my @a=split("\t",$_);
    $sites++;
    $depth+=$a[2];
}
close(F);
print "$id\t$sites\t$depth\n";

