#! /usr/bin/perl
use strict;
use warnings;

my $gff=shift;
die "$0 gff/gff.gz"unless $gff;
if($gff =~ /gz$/){
    open(I,"zcat $gff|");
}else{
    open(I,"$gff");
}

open(O,"|gzip -c > $gff.geneRegion.gz");
open(O2,"> $gff.gene.bed");
while(<I>){
    chomp;
    my ($chr,$type,$start,$end)=(split(/\s+/))[0,2,3,4];
    if($type =~/^gene$/){
	print O "$_\n";
	print O2 "$chr\t$start\t$end\n";
    }
}
close I;
close O;
close O2;
