#!/usr/bin/perl
use warnings;
use strict;

my $pwd=`pwd`;chomp $pwd;

if (@ARGV !=5) {
	print "perl $0 <poplist><bamlist><vcflist><chrlist><outdir>\n";
	exit 0;
}
my ($poplist,$bamlist,$vcflist,$chrlist,$outdir)=@ARGV;
# poplist
open IN,$poplist or die $!;
my %intersting_pop=();
while(<IN>){
    chomp;my @a=split;
    my $i=1;my $num=scalar@a;
    while($i<$num){
        my $sam=$a[$i];
        $intersting_pop{$sam}=1;
        $i++;
    }
}
close IN;
#==============
if( ! -e "$outdir") {`mkdir $outdir`;}
open OUT,'>',"$outdir/step1_vcffile.sh" or die $!;
my %hash=();
open T,$chrlist or die $!;
my %chrome=();while(<T>){chomp;$chrome{$_}=1;}
close T;
open T,$bamlist or die $!;
my %sam=();
while(<T>){
    chomp;
    my ($sample,$bam)=(split)[0,1];
    next unless($intersting_pop{$sample});    
    my $sam_outdir="$pwd/$outdir/MSMCinputfile/$sample";
    if( ! -e "$outdir/MSMCinputfile") {`mkdir "$outdir/MSMCinputfile"`;}
    if( ! -e "$sam_outdir") {`mkdir $sam_outdir`;}    
    $sam{$sample}=1;
}
close T;
if($vcflist eq "Null") {
    foreach my$sample(sort keys %sam){
        foreach my$chr (sort keys %chrome){
            my $sam_outdir="$pwd/$outdir/MSMCinputfile/$sample";
            if(-e "$sam_outdir/$sample.$chr.vcf") {`rm $sam_outdir/$sample.$chr.vcf`;}
            `ln -s $sam_outdir/$sample.$chr.raw.vcf $sam_outdir/$sample.$chr.vcf`;
        }
    }
    last;
}
open IN,$vcflist or die $!;
while(<IN>){
    chomp;
    my ($vcf,$bool)=(split)[0,1];    
    my $chr=$bool;
    foreach my$sample(sort keys %sam){
	my $sam_outdir="$pwd/$outdir/MSMCinputfile/$sample";
	open T,">$sam_outdir/msmc_vcf_$chr.sh" or die $!;
	my $sh=<<Script;
	/home/wanglizhong/software/vcftools/vcftools-build/bin/vcftools --gzvcf $vcf --indv $sample --chr $chr --max-missing 1 --recode --out $sample.$chr
	    Script
	    print T "$sh\n";            
	close T;
	print OUT "cd $sam_outdir;sh msmc_vcf_$chr.sh\n";            
    }          
}
close OUT;
close IN;   
