#! /usr/bin/perl
use strict;
use warnings;

my $file=shift;
die "$0 1.vcf\n" unless $file;

my %h;
open(IN,"$file");
while(<IN>){
    chomp;
    next if(/^#/);
    my @a=split(/\s+/);
    my $a=$a[7];
    #print "$a\n";
    if($a=~ /MQ=(\d+)\;/){
        $h{$1}++;
        next;
    }else{
        $h{erro}++;
    }
}
close IN;
open(OUT,"> $file.MQ.stat");
foreach my $key(sort keys %h){
    print OUT "$key\t$h{$key}\n";
}
close OUT;
