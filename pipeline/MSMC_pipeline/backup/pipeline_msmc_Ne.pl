#!/usr/bin/perl -w
use strict;
use warnings;
my $bin='/ifshk5/BC_COM_P11/F16RD04012/ICEmmrD/bin/MSMC_pipeline/Ne';
use FindBin qw($Bin);
use Getopt::Long;
my $help =<<qq;

****************************************************************************************************

        wenjuan.zhu\@genomics.cn       2015.6.3

****************************************************************************************************

        perl $0 -bamlist -ref -vcflist -chrlist [-o ]
Options:    
    -bamlist: bam from one population (necessary)
    -ref:     reference genome (necessary)
    -depth:   mean depth about these sample (necessary)
    -vcflist: phase vcf file including our sample.format:vcffile\\tALLchr or vcffile\\tchr1;If you don't have vcf file, please Set to "Null".(necessary)
    -chrlist: one chromosome one line, which name of chromosome must be consistant with reference genome.    
    -o:       outdir 
Note:
1:Memory for qsub 
  1)for step1,memory is 0.4G. two step1 shell can be processed,parallelly.
  2)for step2,memory is 0.5G.
  3)for step3, it depends on the sample size, example 70G for 4 individuals(8 haplotypes).
2:For bamlist or vcflist, The format:
  bamlist format: "chr1.bam chr1" or "YH.bam ALLchr"
  vcflist format: "chr1.vcf chr1" or "YH.vcf ALLchr"
  Please notice vcf must have varaints information of all samples that you want to estimate Ne.
3:For vcf format,must be *.vcf.gz;Please use the following commed to deal with your vcffile.
  /ifshk5/BC_COM_P11/F16RD04012/ICEmmrD/bin/software/tabix-0.2.6/bgzip -f chr1.vcf;
  /ifshk5/BC_COM_P11/F16RD04012/ICEmmrD/bin/software/tabix-0.2.6/tabix -p vcf chr1.vcf.gz
qq

my ($bamlist,$ref,$depth,$vcflist,$chrlist,$outdir);
GetOptions(
	"bamlist:s" => \$bamlist,
	"ref:s" => \$ref,
    "depth:s" => \$depth,
    "vcflist:s" => \$vcflist,
    "chrlist:s" => \$chrlist,
	"o:s" => \$outdir,
#	"qsub!" => \$qsub,
);
$ref ||= "/ifshk5/BC_COM_P11/F16RD04012/ICEmmrD/bin/GATK/b37/human_g1k_v37.fasta";
#/ifshk5/BC_COM_P11/F16RD04012/ICEmmrD/bin/GATK/hg19/hg19.fa
$outdir ||= "./";
$vcflist ||= "Null";
die $help if(!$bamlist or !$depth or !$ref);
#==step1 and step2====
`perl $bin/s1.bedfile.pl $bamlist $ref $depth $chrlist $outdir`;
`perl $bin/s1.vcffile.pl $bamlist $vcflist $chrlist $outdir`;
#==step3====
`perl $bin/s3.msmc_run.pl $chrlist $outdir`;

