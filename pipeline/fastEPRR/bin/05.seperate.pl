#! /usr/bin/env perl
use strict;
use warnings;

my %ne;
open(I,"/ifshk5/PC_HUMAN_EU/USER/wanglizhong/project.hk/09.recombination_rate/FaseEPRR/Ne.txt"); ########## you may need change this file; pop_name  Ne
while(<I>){
    chomp;
    my @a=split(/\s+/);
    $ne{$a[0]}=$a[1];
}
close I;

my $dir=`pwd`; chomp $dir;
$dir =~ /\_(\w\w\w)$/;
my $pop=$1;
my $ne=$ne{$pop};


my @recombination=<step3/*>;
foreach my $file(@recombination){
    open O,"> $file.txt";
    print O "chr\tstart\tRho\tr\n";
    open I,"< $file";
    $file=~/chr_([^\/]+)$/;
    my $chr=$1;
    while(<I>){
	chomp;
	/Position\(kb\) ([\d\.]+)-([\d\.]+):/;
	my ($start,$end)=($1,$2);
	$start=int(($start+5)/10)*10;
	$end  =int(($end+5)/10)*10;
	my $mid=($start+$end)/2;
	$start = $start*1000+1;
	$end   = $end*1000+1;
	$mid   = $mid*1000;

	my $value=<I>;
	chomp $value;
	my ($rho,$cil,$cir)=("NA","NA","NA");
	if($value=~/Rho:([\d\.]+) CIL:([\d\.]+) CIR:([\d\.]+)/){
	    ($rho,$cil,$cir)=($1,$2,$3);
	}
	elsif($value=~/Rho:([\d\.]+)/){
	    $rho=$1;
	}
	next if($rho =~ /NA/);
	my $r=$rho/(4*$ne);
	
	print O "$chr\t$start\t$rho\t$r\n";
    }
    close I;
    close O;
}

