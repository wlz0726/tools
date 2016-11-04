my $vcf=shift;
die "$0 ../*.vcf.gz\n"unless $vcf;


$vcf=~ /(.*\/([^\/]*))\.vcf.gz$/;
my $prefix=$2;
my $id=$1;

open(OUT,"> $0.$prefix.sh");
print OUT "/home/wanglizhong/software/vcftools/vcftools-build/bin/vcftools --gzvcf $vcf --plink --out $prefix; \n";
print OUT "perl 5.ChangeMap.pl $prefix.map\n";
close OUT;
`perl 1.runPlink.pl $prefix`;

`perl 4.RunPCA.pl $prefix`;

`perl 8.AdmixtureForOldVCF.pl $prefix`;

#`perl 10.IBS.Het.pl $prefix.2`;
#`perl 10.IBS.Het.pl $prefix.maf0.05`;
#`perl 11.KING.pl $prefix.2`;
#`perl 11.KING.pl $prefix.maf0.05`;
#`perl 12.haploview.LD.pl $prefix`;
