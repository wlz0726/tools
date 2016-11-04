#! /usr/bin/perl
use strict;
use warnings;

my $file=shift;;
my $id;
my $all=0;
my $aln=0;
if($file=~m/(\S+)\.bam$/){
    $id=$1;
}else{
    die "$file\n";
}
#print "$file\n";

open(F, "samtools view $file |");
while(<F>){
    chomp;
    next if(/^\@SQ/);
    my @a=split(/\s+/);
    $aln++ if($a[2] ne "*");
    $all++;
}
close F;
my $per=$aln/$all;
print "$id\taln:$aln\tall:$all\tpercent:$per\n";
