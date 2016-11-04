my $snp_dir=shift;
die "$0 snp_dir\n"unless $snp_dir;

my $out="$snp_dir.tfile";
`mkdir $out`;

open(O,">$out.1.AddAnc.sh");
for(my $i=1;$i<=29;$i++){
    my $vcf="$snp_dir/Chr$i.vcf.gz";
    print O "/home/wanglizhong/software/vcftools/vcftools-build/bin/vcftools --gzvcf $vcf --plink-tped --out $out/Chr$i;";
    print O "perl add_ance.pl /ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/work/Cattle/step2.ancestry/Chr$i.rs.geneticmap.ref.mutus.ancestry.gz $out/Chr$i.tped $out/Chr$i.anc.tped;\n";
}
close O;
