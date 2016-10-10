my $file=shift;
#my $Depth=shift;
#die "$0 bamFile EffectiveDepth\n" unless $Depth;
#my $d=int($Depth/3);
#my $D=int($Depth*2)+1;
print "samtools mpileup -uf ../../ref/yak0803_v2.sca.break.fa.filter2K.fa $file | bcftools view -cg - | vcfutils.pl vcf2fq | gzip > $file.2.fq.gz\n";

## set -d 1/3 of EffectiveDepth; -D 2*EffectiveDepth
