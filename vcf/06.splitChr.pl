#! /usr/bin/perl
use strict;
use warnings;


my $vcf=shift;
my $scaf=shift;
die "perl 06.splitChr.pl vcfFile scaffoldName\n" unless $scaf;
my %h;
$h{$scaf}++;

open(IN,"$vcf");
open(OUT1,">$vcf.$scaf.vcf");
while(<IN>){
    chomp;
    if(/^#/){
        print OUT1 "$_\n";
        next;
    }
    my @a=split(/\s+/);
    if(exists $h{$a[0]}){
        print OUT1 "$_\n";
    }
}
close IN;
close OUT1;
