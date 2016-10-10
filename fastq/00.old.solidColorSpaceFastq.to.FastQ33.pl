#! /usr/bin/perl
use strict;
use warnings;

my $file=shift;
my $id;
if($file=~ /(.*)\.fq.gz/){
    $id=$1;
}elsif($file =~ /(.*)\.fastq.gz/){
    $id=$1;
}
die "$0 fastq.gz/fq.gz" unless $file;
my $out="$id.solid2fq.recode.fq.gz";
open(I1,"zcat $file |")||die("$!\n");
open(O1,"| gzip -c > $out")||die("$!\n");
while(<I1>){
    my $l1=$_;
    my $l2=<I1>;
    my $l3=<I1>;
    my $l4=<I1>;
    
    $l1 =~ s/ /\_/g;
    my $l22=substr($l2,2);
    $l22 =~ tr/0123./ACGTN/;
    my $l42=substr($l4,2);
    print O1 "$l1$l22+\n$l42";
}
close I1;
close O1;
