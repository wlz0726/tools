# Count missing rate of each population and total missing rate of raw SNPs vcf  in /ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/work/Cattle/step1.data/SNP/

my $out="$0.out";
`mkdir $out`;

my @f=<00.rawSNP/*gz>; 
foreach my $f(@f){
    $f =~ /\/final.gatk.snp.(.*).VQSR.vcf.gz/;
    my $chr=$1;
    my $prefix="$out/$chr";
    print "perl MissingRate.pl $f $prefix;\n";
}

