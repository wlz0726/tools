#!/usr/bin/perl
use strict;
use warnings;

my $id=shift;
my $read1=shift;
my $read2=shift;
my $outdir=shift;
my $bin=shift;
#my $bin="100000000"; # 100M reads per file

my $num=1;
my $printnum=1;
open(I1,"zcat $read1|");
open(I2,"zcat $read2|");
open(O1,"|gzip -c > $outdir/$id.split$printnum\_1.fastq.gz");
open(O2,"|gzip -c > $outdir/$id.split$printnum\_2.fastq.gz");
while(<I1>){
    my $r1=$_;
    my $r2=<I1>;
    my $r3=<I1>;
    my $r4=<I1>;
    my $print1="$r1$r2$r3$r4";
    
    my $r5=<I2>;
    my $r6=<I2>;
    my $r7=<I2>;
    my $r8=<I2>;
    my $print2="$r5$r6$r7$r8";
    #my $flag=($num%$bin);
    #print "$flag\n";
    
    if(($num%$bin) == 0){
	print O1 "$print1";
	print O2 "$print2";
	close O1;
	close O2;
	print "===========split $printnum done\n";
	$printnum++;
	open(O1,"|gzip -c > $outdir/$id.split$printnum\_1.fastq.gz");
	open(O2,"|gzip -c > $outdir/$id.split$printnum\_2.fastq.gz");
    }else{
	print O1 "$print1";
        print O2 "$print2";
    }
    $num++;
}
close I1;
close I2;
close O1;
close O2;
