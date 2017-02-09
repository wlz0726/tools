#!/usr/bin/perl -w
use strict;
use warnings;
use FindBin qw($Bin);
use Getopt::Long;

# configure
my $bin="/home/wanglizhong/tools/msmc/relative-cross-coalescence-rate/bin";

#

my $help =<<qq;
        perl $0 -bamlist -ref -vcflist -chrlist [-o ]

Options:    
    -bamlist: bam from one population (necessary)
    -ref:     reference genome (necessary)
    -depth:   mean depth about these sample (necessary)
    -poplist: population information;Format:'China YH1 YH2' or 'China YH1'; (necessary)
    -vcflist: phase vcf file including our sample.format:vcffile\\tALLchr or vcffile\\tchr1;If you don't have vcf file, please Set to "Null".(necessary)
    -chrlist: one chromosome one line, which name of chromosome must be consistant with reference genome.    
    -poppair: only estimate specific population pairs in this file.(option)
    -o:       outdir [outdir]

Note:
1:Memory for qsub 
  1)for step1,memory is 0.4G. two step1 shell can be processed,parallelly.
  2)for step2,memory is 0.5G.
  3)for step3, it depends on the sample size, example 70G for 4 individuals(8 haplotypes),25G for 2individuals (4 haplotype); 200~300 G for 8haps in Coalescencerate model

2:For bamlist or vcflist, The format:
  bamlist format: "SampleID chr1.bam chr1" or "SampleID YH.bam ALLchr"
  vcflist format: "chr1.vcf.gz chr1" or "YH.vcf.gz ALLchr"
  poplist format: "Pop Ind1" per line
  poppair format: "YRI:CEU"
  Please notice vcf must have varaints information of all samples that you want to estimate Ne.
3:For vcf format,must be *.vcf.gz;Please use the following commed to deal with your vcffile.
  /ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/bin/software/tabix-0.2.6/bgzip -f chr1.vcf;
  /ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/bin/software/tabix-0.2.6/tabix -p vcf chr1.vcf.gz
4:MSMC paper:
1) With two haplotypes, MSMC infers the population history from 40,000 to 3 million years ago, whereas,
with four and eight haplotypes, it infers the population history from 8,000 to 30,000 years ago and from 2,000 to 50,000 years ago,respectively.
2) As expected, four haplotypes yield good estimates for the older split, whereas eight haplotypes give better estimates for the more recent split.

qq

my ($bamlist,$ref,$depth,$poplist,$vcflist,$chrlist,$poppair,$outdir);
GetOptions(
    "bamlist:s" => \$bamlist,
	"ref:s" => \$ref,
      "depth:s" => \$depth,
    "poplist:s" => \$poplist,
    "vcflist:s" => \$vcflist,
    "chrlist:s" => \$chrlist,
    "poppair:s" => \$poppair,
	  "o:s" => \$outdir,
);
$ref ||= "/ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/bin/GATK/b37/human_g1k_v37.fasta";
$outdir ||= "group";
$vcflist ||= "Null";
$poppair ||= "Null";
die $help if(!$bamlist or !$depth or !$ref or !$poplist);
#==step1======
`perl $bin/s1.bedfile.pl $poplist $bamlist $ref $depth $chrlist $outdir`;
`perl $bin/s1.vcffile.pl $poplist $bamlist $vcflist $chrlist $outdir`;
#==step3====
if($poppair eq "Null"){
`perl $bin/s2.msmc.pl $poplist $chrlist $outdir`;
}
else{
    `perl $bin/s2.msmc_option.pl $poplist $poppair $chrlist $outdir`;
}
