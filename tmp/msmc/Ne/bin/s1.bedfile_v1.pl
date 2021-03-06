#!/usr/bin/perl
use warnings;
use strict;
#tongji
if (@ARGV !=5) {
	print "perl $0 <bamlist><ref><depth><chrlist><outdir>\n";
	exit 0;
}
my ($bamlist,$ref,$depth,$chrlist,$outdir)=@ARGV;
if($bamlist=~/.gz/) {open IN,"zcat $bamlist|" or die $!;}  else{open IN,$bamlist or die $!;}
open T,$chrlist or die $!;
my %chrome=();while(<T>){chomp;$chrome{$_}=1;}
close T;

open BED,'>',"$outdir/step1_bedfile.sh" or die $!;
open TXT,'>',"$outdir/step2_msmc_inputfile.sh" or die $!;
my %hash=();
my $sh=<<Script;
export LD_LIBRARY_PATH=/opt/blc/python-3.1.2/lib:\$LD_LIBRARY_PATH;
python='/opt/blc/python-3.1.2/bin/python3.1'
samtools='/ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/bin/software/samtools-0.1.19/samtools'
bcftools='/ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/bin/software/samtools-0.1.19/bcftools/bcftools'
tools='/ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/bin/software/history/MSMC/msmc-master/tools'
ref=$ref
Script
my $ave_depth=$depth;
my %sum_vcf =();
my %sum_mask=();
while(<IN>){
    chomp;
    my ($sample,$bam)=(split)[0,1];
    my $sam_outdir="$outdir/MSMCinputfile/$sample";
    if( ! -e "$outdir") {`mkdir $outdir`;}
    if( ! -e "$outdir/MSMCinputfile") {`mkdir "$outdir/MSMCinputfile"`;}
    if( ! -e "$sam_outdir") {`mkdir $sam_outdir`;}
    foreach my $chr(sort keys %chrome){
        open T,">$sam_outdir/msmc_bed_$chr.sh" or die $!;
my $sh2=<<Script;
cd $sam_outdir
date
echo start
\$samtools mpileup -q 20 -Q 20 -C 50 -u -r $chr -P ILLUMINA -f \$ref $bam|\$bcftools view -cgI - |\$python \$tools/bamCaller.py $ave_depth $sample.$chr.mask.bed > $sample.$chr.raw.vcf
date
echo end

Script
        print T "$sh\n$sh2\n";
        close T;
        print BED "cd $sam_outdir;sh msmc_bed_$chr.sh\n";
        $sum_vcf{$chr} .=" $sam_outdir/$sample.$chr.vcf";
        $sum_mask{$chr}.=" --mask $sam_outdir/$sample.$chr.mask.bed";
    }
}

foreach my $key (sort keys %sum_vcf){    
    print TXT "cd $outdir/MSMCinputfile;export LD_LIBRARY_PATH=/opt/blc/python-3.1.2/lib:\$LD_LIBRARY_PATH;/opt/blc/python-3.1.2/bin/python3.1 /ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/bin/software/history/MSMC/msmc-master/tools/generate_multihetsep.py $sum_mask{$key} $sum_vcf{$key} > msmc.$key.txt\n";
}
close BED;
close TXT;
close IN;   
