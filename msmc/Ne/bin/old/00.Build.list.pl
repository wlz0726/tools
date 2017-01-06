open(I,"/ifshk5/PC_HUMAN_EU/USER/wanglizhong/project.hk/1608.PSMC.cattle/PSMC.bam.list");
open(O,"> bamlist");
open(O2,"> poplist");
open(O3,"> depthlist");
while(<I>){
    chomp;
    next if(/\=/ || /\-/);
    my @a=split(/\s+/);
    print O "$a[1]\t$a[3]\tALLchr\n";
    print O2 "$a[0]\t$a[1]\n";
    print O3 "$a[1]\t$a[2]\n";
}
close I;
close O;
close O2;
close O3;


my @vcf=</ifshk5/PC_HUMAN_EU/USER/zhuwenjuan/work/Cattle/step2.phase/result/VCF/*.phased.vcf.gz>;
open(O,"> vcflist");
open(O2,"> chrlist");
foreach my $f(@vcf){
    $f =~ /VCF\/(Chr.+).phased.vcf.gz/;
    next if($1 =~ /X/);
    print O "$f $1\n";

    print O2 "$1\n";
}
close O;
close O2;
