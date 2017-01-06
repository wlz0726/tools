#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Std;

# author: wanglizhong
# date  : 2016.12.20

my %opts=(b=>'',r=>'',c=>'22',m=>'1',v=>'',o=>"$0.out");
getopts('b:r:c:m:v:o:', \%opts);
die("
        Usage:   $0 -b bamlist -r ref.fa -m 1 -o outprefix\n
        Options:
        -b file        : bamfile with 4 coloums:  <Population_name> <Sample_name> <Mean_Depth> <Bam_path>
        -r reference   : reference
        -c chr_number  : chr numbers [$opts{c}]
        -m INT         : [$opts{m}]
                          1: de novo call SNP info; for samples with sequencing depth >20x
                          2: based on phase SNPs; better for for samples with low depth <20x
        -v DIR         : directory with all vcf files, each chromosome in a file like this 'chr1.vcf.gz'; or you need to change some part of this script
        -o outprefix   : Output directory prefix  [$opts{o}]
        Note: you may want to edit the 'related files and software' part of this script first
        \n") unless ($opts{b});

if($opts{m} == 2){
    die("Erro: -m 2 depend on -v DIR parameter \n")unless $opts{v};
}

print "-bam $opts{b}\n";
# related files and software ==================================
my $ref="/home/wanglizhong/project/04.zangyi.F13FTSNWKF2248_HUMmuzR/ref/hg19.fasta"||$opts{r};
my $vcfdir="/home/wanglizhong/project/04.zangyi.F13FTSNWKF2248_HUMmuzR/02.SNP/phased"||$opts{v}; # only need for mode 2
# software
my $samtools="/ifshk4/BC_PUB/biosoft/PIPE_RD/Package/samtools-0.1.19/samtools";
my $bcftools="/ifshk4/BC_PUB/biosoft/PIPE_RD/Package/samtools-0.1.19/bcftools/bcftools";
my $vcfutils="/ifshk4/BC_PUB/biosoft/PIPE_RD/Package/samtools-0.1.19/bcftools/vcfutils.pl";
my $vcftools="/home/wanglizhong/software/vcftools/vcftools-build/bin/vcftools";
# scripts
my $vcf2fq="/home/wanglizhong/tools/pipeline/PSMC/bin/vcf2fq.pl";
# psmc related
my $fq2psmcfa="/home/wanglizhong/software/psmc/psmc-0.6.5/utils/fq2psmcfa";
my $psmc="/home/wanglizhong/software/psmc/psmc-0.6.5/psmc";
my $splitfa="/home/wanglizhong/software/psmc/psmc-0.6.5/utils/splitfa";
#==============================================================


#######
my $out=$opts{o};
`mkdir $out`unless -e $out;

## read bam list
open (F,"$opts{b}")||die"No such file: bamlist";
open(O1,"> $out.step1.fq.sh");
open(O2,"> $out.step2.psmc.sh");
open(O3,"> $out.step3.bt.sh");
open(O4,"> $out.step4.removeTMPfiles.sh");
while(<F>){
    chomp;
    my @a=split(/\s+/);
    my $pop=$a[0];
    my $id=$a[1];
    my $depth=$a[2];
    my $bam=$a[3];
    
    `mkdir -p $out/$pop`;
    my $prefix="$out/$pop/$id";
    
    my $mindepth=int($depth/3);
    my $maxdepth=int($depth*3)+1;
    # step1 : for each chr
    for(my $i=1;$i<=$opts{c};$i++){
	        
	if($opts{m} ==1){
	    # Method 1: de novo call SNP info; for samples with sequencing depth >20x
	    print O1 "$samtools mpileup -C50 -uf $ref -r chr$i $bam | $bcftools view -c -  | $vcfutils vcf2fq -d $mindepth -D $maxdepth -Q 10 -l 5 |gzip -c > $prefix.Chr$i.fq.gz; $fq2psmcfa -q20 $prefix.Chr$i.fq.gz >$prefix.Chr$i.psmcfa;\n"; # chr1 ; # edit this
	}elsif($opts{m} ==2){
	    # Method 2: based on phase SNPs; better for for samples with low depth <20x
	    my $vcf="$vcfdir/chr$i.vcf.gz"; # edit this
	    print O1"$vcf2fq $ref $vcf chr$i |gzip -c > $prefix.Chr$i.fq.gz; $fq2psmcfa -q20 $prefix.Chr$i.fq.gz > $prefix.Chr$i.psmcfa; \n";
	}
	# step4: remove tmp files
	print O4 "rm $prefix.Chr$i.vcf.gz $prefix.Chr$i.fq.gz $prefix.Chr$i.psmcfa; \n";
    }
    
    # step2: merge psmcfa files of each chrs and run psmc
    print O2 "cat $prefix.Chr*.psmcfa > $prefix.allchr.psmcfa; $psmc -N25 -t15 -r5 -p \"4+25*2+4+6\" -o $prefix.allchr.psmc $prefix.allchr.psmcfa;\n";
    # step3: running psmc with 100 bootstraps
    print O3 "$splitfa $prefix.allchr.psmcfa > $prefix.allchr.split.psmcfa ; mkdir -p $out/$pop/$id.bt; ";
    for(my $j=1;$j<=100;$j++){
	print O3 "$psmc -N25 -t15 -r5 -b -p \"4+25*2+4+6\" -o $out/$pop/$id.bt/$id.$j.psmc $prefix.allchr.split.psmcfa; ";
    }
    print O3 "cat $prefix.allchr.psmc $out/$pop/$id.bt/$id.*.psmc > $prefix.allchr.bootrstrap.psmc;\n";
}
close F;
close O1;
close O2;
close O3;
close O4;
