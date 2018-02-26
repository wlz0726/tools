use strict;
use warnings;

# gatk 3.6-0-g89b7209

my @scaffold=<01.vcfByWindow/*/interver.list>;

my @bam;
open (F,"00.bam.list");
while (<F>) {
    chomp;
    push @bam,$_;
}
close F;

open (O,">$0.split.sh");
open (O1,">$0.All.sh");
for my $scaffold (@scaffold){
    $scaffold=~/^(\S+)\/(\d+)\/interver.list/;
    ($scaffold,my $dir)=($2,$1);
    for my $bam (@bam){
        $bam=~/\/(\w+)\.realn.bam$/;
        my $id=$1;
        print O "/usr/bin/java -jar /home/share/users/yangyongzhi2012/tools/GATK/GenomeAnalysisTK.jar -T HaplotypeCaller -R /home/pool/users/yangyongzhi2012/Ostrya_resequnce/00.ref/Ore.final.assembly.flt.2k.fa -I $bam -nct 30 -ERC GVCF -L $dir/$scaffold/interver.list -o $dir/$scaffold/$id.gvcf.gz -variant_index_type LINEAR -variant_index_parameter 128000 2>&1 | tee $dir/$scaffold/$id.gvcf.log\n";
    }
        print O1 "/usr/bin/java -jar /home/share/users/yangyongzhi2012/tools/GATK/GenomeAnalysisTK.jar -T HaplotypeCaller -R /home/pool/users/yangyongzhi2012/Ostrya_resequnce/00.ref/Ore.final.assembly.flt.2k.fa -I 00.bam.list -nct 30 -L $dir/$scaffold/interver.list -o $dir/$scaffold/All.vcf.gz -variant_index_type LINEAR -variant_index_parameter 128000 2>&1 | tee $dir/$scaffold/All.gvcf.log\n";
    
}
close O;
close O1;
