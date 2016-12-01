#!/usr/bin/perl
use warnings;
use strict;

if (@ARGV !=2 ) {
	print "perl $0 <cnvnator.result><filter.result>\n";
	exit 0;
}
my ($in,$out)=@ARGV;
if($in=~/.gz/) {open IN,"zcat $in|" or die $!;}  else{open IN,$in or die $!;}
# genome N regions
open N,'/ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/bin/perl/callSV/CNVnator/b37_N_region.txt' or die $!;
my %N_region=();
while(<N>){
    chomp;
    #chr1    177418  227417
    my ($chr,$s,$e)=(split(/\s+/,$_))[0,1,2];
    if($chr=~/chr(\w+)/) {$chr=$1;}
    my $key="$chr:$s:$e";$N_region{$key}=1;
}
close N;

#
open OUT,'>',$out or die $!;
my %hash=();

while(<IN>){
    chomp;
    my @s=split(/\s+/,$_);
    my ($type,$cnv,$len,$rd,$p1,$p2,$mp1,$mp2,$q0)=(@s)[0,1,2,3,4,5,6,7,8];
    my ($chr,$str)=(split(/\:/,$cnv))[0,1]; 
#    if($chr=~/chr(\w+)/) {$chr=$1;}
#    next unless($chr=~/^(\d+)$/ || $chr eq "X" || $chr eq "Y");
    my ($s,$e)=(split(/\-/,$str))[0,1];
#==============
#my $bool=CHECK_N($type,$chr,$s,$e);if(! $bool) {next;}
#if($chr=~/chr(\w+)/) {$chr=$1;}
#next unless($chr=~/^(\d+)$/ || $chr eq "X" || $chr eq "Y");
    if($type eq 'deletion') {
	next if($q0>0.5);
	if($len>2000)  {  
	    next if($mp1>0.05 || $mp2<1.645);
	} #0.05 :little probability
	else {
	    next if($p1>0.05 || $p2<1.645);
	} 
    }
    elsif($type eq 'duplication'){
	if($len>2000)  {  
	    next if($mp1>0.05 || $mp2<1.645);
	} #0.05 :little probability
	else {
	    next if($p1>0.05 || $p2<1.645);
	}
    }
    else{next;}
    s/chr//g;
    print OUT "$_\n";
}

close OUT;
close IN;   
sub CHECK_N {
    my $type=shift;my $chrom=shift;my $cnv_s=shift;my $cnv_e=shift;
    my $bool=0;
    foreach my $key (sort keys %N_region){
	my ($chr,$s,$e)=(split(/\:/,$key))[0,1,2];
	next unless($chrom eq $chr);
	if($type eq 'deletion') { #it!does!not!overlap!a!gap!in!the!reference!genome!for!a!deletion;
	    #if(($cnv_s>=$s && $cnv_s<=$e) && ($cnv_e>=$s && $cnv_e<=$e)) {$bool=1;}
	    if($cnv_s<=$s && $e<=$cnv_e) {$bool=1;}
	    elsif($cnv_s>=$s && $cnv_s<=$e) {$bool=1;}
	    elsif($cnv_e>=$s && $cnv_e<=$e) {$bool=1;}
	    else{next;}
	}
	elsif($type eq 'duplication'){ #it!is!not!within!0.5!Mb!from!a!gap!in!the!reference!genome!for!a!duplication;
	    if(($cnv_s>=$s && $cnv_s<=$e) && ($cnv_e>=$s && $cnv_e<=$e)){$bool=1;}
	    elsif($cnv_s<=$s && $e<=$cnv_e) {$bool=1;}
	    elsif($cnv_s>=$s && $cnv_s<=$e) {$bool=1;}
	    elsif($cnv_e>=$s && $cnv_e<=$e) {$bool=1;}
	    elsif($s-$cnv_e<500000 && $s-$cnv_e>=0) {$bool=1;}
	    elsif($cnv_s-$e<500000 && $cnv_s-$e>=0) {$bool=1;}
	    else{next;}
	    
	}
	else {next;}
    }
    if($bool) {return 0;}
    else {return 1;}
    
}
