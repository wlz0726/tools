#! /usr/bin/perl
use strict;
use warnings;

my $fst=shift;
my $p=shift;
die "000.filter.fst.pl fst p-threshold\n" unless $p;
open(IN,"$fst");
open(OUT,"> $fst.$p.fst");
while(<IN>){
    chomp;
    my @a=split(/\s+/);
    next if($a[4] < $p);
    print OUT "$_\n";
}
close IN;
close OUT;
