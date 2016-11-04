# /ifshk4/BC_PUB/biosoft/PIPE_RD/Package/samtools-1.2/samtools-1.2/bin/samtools mpileup -C 50 -q 30 -Q 20 -r -f /ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/work/Cattle/step1.data/reference/UMD3.1.fasta -r Chr1 -ug Yak.bam |

my $bam="bam/Bison_bison8.bam bam/Bos_gaurus4.bam bam/Bos_gaurus5.bam bam/Bos_grunniens3.bam bam/Bos_javanicus7.bam bam/Bubalus_bubalis1.bam bam/Gayal.bam bam/Yak.bam";
die "$0 bam\n"unless $bam;
# samtools mpileup -A -ug -t DP4 -t SP -f $ref -r $chr *.bam | bcftools call -mO z -o $outdir/$chr.vcf.gz

my $ref="/ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/work/Cattle/step1.data/reference/UMD3.1.fasta";
my $outdir="$0.out";
`mkdir -p $outdir/tmp`;
my $samtools="/ifshk4/BC_PUB/biosoft/PIPE_RD/Package/samtools-1.2/samtools-1.2/bin/samtools";
my $bcftools="/ifshk5/PC_HUMAN_EU/USER/wanglizhong/software/samtools/bcftools/bcftools";

open(O,"> $0.sh");
my @chr=(1..29,X);
foreach my $chr(@chr){
    my $chr_name="Chr$chr";
    #print O "$samtools mpileup -A -ug -t DP4 -t SP -f $ref -r $chr_name $bam | $bcftools call -mO z -o $outdir/$chr_name.vcf.gz;\n";
    print O "$samtools mpileup -ug -t DP4 -t SP -C 50 -q 30 -Q 20 -f $ref -r $chr_name $bam | $bcftools call -mO z -o $outdir/$chr_name.vcf.gz;\n";
    
}
close O;
