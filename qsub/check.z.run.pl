#!/usr/bin/perl -w
use strict;
use warnings;

my $dir=shift;
die "$0 z.01.MSMC.RelativeCrossCoalescenceRate.pl.1.bed.sh.z\n"unless $dir;
`grep done $dir/*o > ./tmmmmmmmp`;
my %h;
open(I,"./tmmmmmmmp");
while(<I>){
    chomp;
    if(/(.*.pbs).(\d+).o\:done/){
	#print $1,"\n";
	$h{$1}=$2;
    }else{
	print "$_\n";
    }
}
close I;

my @f=<$dir/*pbs>;
foreach my $f(@f){
    if(exists $h{$f}){
	next;
    }
    #`ls $f.*`;
    print "qsub $f\n";
}

`rm ./tmmmmmmmp`;
