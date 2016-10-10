#! /usr/bin/perl
use strict;
use warnings;

my $file=shift;
my $line=shift;
die "$0 file lineNum\n" unless $line;

my $line1=$line-1;
my $total=0;
my $num=0;
open(IN, "$file");
while(<IN>){
    chomp;
    my @a=split(/\s+/);
    next if ($a[$line1] =~ /nan/);
    $total += $a[$line1];
    $num++;
}
close IN;
my $mean =$total/$num;
print "$file\t mean value of Row $line: $mean
total:$total num:$num\n";
