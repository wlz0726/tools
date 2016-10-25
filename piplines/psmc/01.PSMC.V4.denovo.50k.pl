my $bamlist="02.print.list.pl.bamlist";
#"PSMC.bam.list"; # each bam per line with four cols:Pop_name Sample_name Mean_Depth Bam_Path

# related files and software ==================================
my $ref="/ifshk5/PC_HUMAN_EU/USER/wanglizhong/projects/project.2.RATxdeR/ref/S.galili.v1.0.fa.Length.50000.fa";
#"/ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/work/Cattle/step1.data/reference/UMD3.1.fasta";
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
open(O1,"> $0.step1.parallel.sh");
#open(O2,"> $0.step2.psmc.sh");
open(O3,"> $0.step3.bt.sh");
open(O4,"> $0.step4.sh");
while(<F>){
    chomp;
    next if(/^=/ || /^-/);
    my @a=split(/\s+/);
    my $pop=$a[0];
    my $id=$a[1];
    my $depth=$a[2];
    my $bam0=$a[3];
    my $bam="$bam0.bam";
    print O1 "perl filter50k.bam.pl $bam0 $bam; $samtools index $bam;";
    
    `mkdir -p $out/$pop`;
    my $prefix="$out/$pop/$id";
    
    my $mindepth=int($depth/3);
    my $maxdepth=int($depth*3)+1;
    
    print O1 "$samtools mpileup -C50 -uf $ref $bam | $bcftools view -c -  | $vcfutils vcf2fq -d $mindepth -D $maxdepth -Q 10 -l 5 |gzip -c > $prefix.allchr.fq.gz; $fq2psmcfa -q20 $prefix.allchr.fq.gz >$prefix.allchr.psmcfa; ";

    # running psmc
    print O1 " $psmc -N25 -t15 -r5 -p \"4+25*2+4+6\" -o $prefix.allchr.psmc $prefix.allchr.psmcfa;";
    # running psmc with 100 bootstraps
    print O1 "$splitfa $prefix.allchr.psmcfa > $prefix.allchr.split.psmcfa ; mkdir -p $out/$pop/$id.bt; \n";
    for(my $j=1;$j<=100;$j++){
	print O3 "$psmc -N25 -t15 -r5 -b -p \"4+25*2+4+6\" -o $out/$pop/$id.bt/$id.$j.psmc $prefix.allchr.split.psmcfa; \n";
    }
    print O4 "cat $prefix.allchr.psmc $out/$pop/$id.bt/$id.*.psmc > $prefix.allchr.bootrstrap.psmc;\n";
}
close F;
close O1;
#close O2;
close O3;
close O4;
