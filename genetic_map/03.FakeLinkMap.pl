open(OUT,"> $0.sh");
my @f=<SNP/\*gz>;
foreach my $f (@f){
    $f =~ /\/final.gatk.snp.Chr(.*).VQSR.vcf.gz/;
    my $chr=$1;
    print OUT "perl FakeLinkMap.pl $f; \n";
}
close OUT;
