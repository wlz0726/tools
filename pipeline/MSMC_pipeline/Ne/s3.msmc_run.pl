#!/usr/bin/perl
use warnings;
use strict;
#tongji
if (@ARGV !=2) {
	print "perl $0 <chrlist><outdir>\n";
	exit 0;
}
my ($chrlist,$outdir)=@ARGV;
open OUT,'>',"$outdir/step3_msmc_Ne.sh" or die $!;
open T,$chrlist or die $!;
my %chrome=();
my $sum_txt="";
my $pop=(split(/\//,$outdir))[-1];
if($pop){;} else{$pop=(split(/\//,$outdir))[-2];}
while(<T>){
    chomp;
    my $chr=$_;
    $chrome{$chr}=1;
    $sum_txt.=" $outdir/MSMCinputfile/msmc.$chr.txt";
}
close T;
print OUT "/ifshk5/BC_COM_P11/F16RD04012/ICEmmrD/bin/software/history/MSMC/msmc -R -o Ne.outfile -i 50 -t 10 -p '15*1+15*2' $sum_txt\n";
close OUT;

