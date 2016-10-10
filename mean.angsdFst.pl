#! /usr/bin/perl
use strict;
use warnings;


my $file=shift;
my $line=shift;
my $linenum=shift;
die "$0 file clumNum totalLineNum\n" unless $linenum;
my $line1=$line-1;
my $total=0;
my $num=0;
my $l=1;
open(IN, "$file");
open(OUT, "> $file.$linenum.fst");
while(<IN>){
    chomp;
    next if($l > $linenum);
    my @a=split(/\s+/);
    if($a[$line1] =~ /[-e\d]+/){
        if($a[$line1] > -1){
            $total +=$a[$line1];
            $num++;
        }
    }
    $l++;
    print OUT "$_\n";
}
close IN;
close OUT;
my $mean =$total/$num;
print "$file\t mean value of Row $line: $mean
total:$total num:$num\n";
