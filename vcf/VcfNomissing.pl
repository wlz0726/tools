#!/usr/bin/perl
use strict;
use warnings;

my $f=shift;
$f =~ /(.*)\.vcf/;
my $out="$1NoMissing.vcf";

my $num=0;
open(IN, "$f");
open(OUT, "> $out");
open(OUT1, "> $out.SNPnum");
while(<IN>){
    chomp;
    if(/^#/){
        print OUT "$_\n";
        next;
    }
    
    next if(/\.\/\./);
    next if(/INDEL/);
    
    my $next=0;
    
    if(/\sPL:DP:SP/){
        my @a=split (/\s+/);
        for(my $i=9;$i<@a;$i++){
            my @b=split (":",$a[$i]);
            #print "$a[$i]\t$i\t$b[1]\n";
            if($b[1] < 2){
	$next++;
	last;
            }
        }
    }elsif(/GT:PL:DP:SP:GQ/){
        my @a=split (/\s+/);
        for(my $i=9;$i<@a;$i++){
            my @b=split (/:/,$a[$i]);
            if($b[2] < 2){
	$next++;
	last;
            }
        }
    }
    if($next == 0){
        print OUT "$_\n";
    }
    $num++;
}
close IN;
close OUT;
print OUT1 "$f no missing num:\t$num\n";
close OUT1;

