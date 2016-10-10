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
    $total +=$a[$line1];
    $num++;
}
close IN;
open(OUT,"> $file.$line.log");
my $mean =$total/$num;
print "$file\n mean value of Row $line: $mean \n(total:$total num:$num)\n";
print OUT "$file\n mean value of Row $line: $mean \n(total:$total num:$num)\n";
close OUT;
