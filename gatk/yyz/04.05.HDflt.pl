use strict;
use warnings;

my $out="$0.out";
my @in=<04.join_by_chr/OreOmu.*.raw.vcf.gz>;
for my $in (@in){
    $in=~/\/OreOmu\.(\w+)/;
    my $chr=$1;
    print "/usr/bin/java -jar /home/share/users/yangyongzhi2012/tools/GATK/GenomeAnalysisTK.jar -T SelectVariants -R /home/pool/users/yangyongzhi2012/Ostrya_resequnce/00.ref/Ore.final.assembly.flt.2k.fa -V $in -selectType SNP -o $out/OreOmu.$chr.raw.SNP.vcf.gz ; /usr/bin/java -jar /home/share/users/yangyongzhi2012/tools/GATK/GenomeAnalysisTK.jar -T VariantFiltration -R /home/pool/users/yangyongzhi2012/Ostrya_resequnce/00.ref/Ore.final.assembly.flt.2k.fa -V $out/OreOmu.$chr.raw.SNP.vcf.gz --filterExpression \"QD < 2.0 || FS > 60.0 || MQ < 40.0 || MQRankSum < -12.5 || ReadPosRankSum < -8.0\"  --filterName \"my_snp_filter\" -o $out/OreOmu.$chr.HDflt.SNP.vcf.gz ; /usr/bin/java -jar /home/share/users/yangyongzhi2012/tools/GATK/GenomeAnalysisTK.jar -T SelectVariants -R /home/pool/users/yangyongzhi2012/Ostrya_resequnce/00.ref/Ore.final.assembly.flt.2k.fa -V $in -selectType INDEL -o $out/OreOmu.$chr.raw.INDEL.vcf.gz ; /usr/bin/java -jar /home/share/users/yangyongzhi2012/tools/GATK/GenomeAnalysisTK.jar -T VariantFiltration -R /home/pool/users/yangyongzhi2012/Ostrya_resequnce/00.ref/Ore.final.assembly.flt.2k.fa -V $out/OreOmu.$chr.raw.INDEL.vcf.gz --filterExpression \"QD < 2.0 || FS > 200.0 || ReadPosRankSum < -20.0\" --filterName \"my_indel_filter\" -o $out/OreOmu.$chr.HDflt.INDEL.vcf.gz\n";
}
