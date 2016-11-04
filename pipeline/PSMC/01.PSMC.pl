my $bamlist="PSMC.bam.list"; # each bam per line with four cols:Pop_name Sample_name Mean_Depth Bam_Path

# related files and software ==================================
my $ref="/ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/work/Cattle/step1.data/reference/UMD3.1.fasta";
my $samtools="/ifshk4/BC_PUB/biosoft/PIPE_RD/Package/samtools-0.1.19/samtools";
my $bcftools="/ifshk4/BC_PUB/biosoft/PIPE_RD/Package/samtools-0.1.19/bcftools/bcftools";
my $vcftools="/home/wanglizhong/software/vcftools/vcftools-build/bin/vcftools";
my $vcf2fq="/ifshk5/PC_PA_EU/PMO/F13FTSNCKF1344_SHEtbyR/zhuwenjuan/s7.history/PSMC/bin/vcf2fq.pl";
my $fq2psmcfa="/ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/bin/software/psmc-master/utils/fq2psmcfa";
my $psmc="/ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/bin/software/psmc-master/psmc";
my $vcfutils="/ifshk4/BC_PUB/biosoft/PIPE_RD/Package/samtools-0.1.19/bcftools/vcfutils.pl";
my $splitfa="/ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/bin/software/psmc-master/utils/splitfa";
#==============================================================
# created by wanglizhong<at>genomics.cn
my $out="$0.out";
`mkdir $out`;

open (F,"$bamlist")||die"$!";
open(O1,"> $0.step1.fq.sh");
open(O2,"> $0.step2.psmc.sh");
open(O3,"> $0.step3.bt.sh");
while(<F>){
    chomp;
    next if(/^=/ || /^-/);
    my @a=split(/\s+/);
    my $pop=$a[0];
    my $id=$a[1];
    my $depth=$a[2];
    my $bam=$a[3];
    
    `mkdir -p $out/$pop`;
    my $prefix="$out/$pop/$id";
    
    my $mindepth=int($depth/3);
    my $maxdepth=int($depth*3)+1;
    
    for(my $i=1;$i<=29;$i++){
	# Three ways to get SNP info
	
        # Method 1: de novo call SNP info; for samples with sequencing depth > 30 x
	# print O1 "$samtools mpileup -C50 -uf $ref -r Chr$i $bam | $bcftools view -c -  | $vcfutils vcf2fq -d $mindepth -D $maxdepth -Q 10 -l 5 |gzip -c > $prefix.Chr$i.fq.gz; $fq2psmcfa -q20 $prefix.Chr$i.fq.gz >$prefix.Chr$i.psmcfa;\n";
	
	# Method 2: based on unphased SNPs obtained with population data
	# my $vcf="/ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/work/Cattle/step1.data/SNP/final.gatk.snp.Chr$i.VQSR.vcf.gz";
	
	# Method 3: based on phase SNPs; perfect for samples with low depth (<20x)
	my $vcf="/ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/work/Cattle/step2.phase/result/VCF/Chr$i.phased.vcf.gz";
	print O1 "$vcftools --gzvcf $vcf --indv $id --recode -c|gzip -c >  $prefix.Chr$i.vcf.gz; $vcf2fq $ref $prefix.Chr$i.vcf.gz Chr$i |gzip -c > $prefix.Chr$i.fq.gz; $fq2psmcfa -q20 $prefix.Chr$i.fq.gz > $prefix.Chr$i.psmcfa; \n";
    }
    # running psmc
    print O2 "cat $prefix.Chr*.psmcfa > $prefix.allchr.psmcfa; $psmc -N25 -t15 -r5 -p \"4+25*2+4+6\" -o $prefix.allchr.psmc $prefix.allchr.psmcfa;\n";
    # running psmc with 100 bootstraps
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
