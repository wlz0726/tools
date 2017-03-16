# vcf.gz need .tbi index
print O2 "export JAVAHOME=/home/wanglizhong/software/java/jre1.8.0_45; /ifshk4/BC_PUB/biosoft/PIPE_RD/Package/java/jre1.8.0_45/bin/java -jar /home/wanglizhong/software/gatk/GenomeAnalysisTK.jar -T CombineVariants -R /home/wanglizhong/project/04.zangyi.F13FTSNWKF2248_HUMmuzR/ref2/hg19.v2.fasta -nt 15 --variant $out/chr$chr.vcflist -genotypeMergeOptions UNIQUIFY -minN 15  --suppressCommandLineHeader |gzip -c > $out/chr$chr.merge.vcf.gz;\n";


# vcf.gz need .csi index
/home/wanglizhong/software/samtools/bcftools/bcftools merge -0 --merge all --no-version --threads 10 1.vcf.gz 2.vcf.gz ...