vcf2fa
======

Given a vcf and a set of bam files, generate consensus sequences for each individual (taking into account areas of low/no coverage)

###Required Software:
- python http://www.python.org/downloads/
- biopython http://biopython.org/wiki/Download
- bedtools https://github.com/arq5x/bedtools2


###Prerequisites:
- reference fasta
- sorted, indexed bam files for each sample, mapped to your reference
- vcf file corresponding to bam files
 e.g.

```bash
samtools mpileup -uDf ref.fasta *.bam | bcftools view -vcg - > var.vcf
```

###STEP 1:
*Caveat: samples MUST be in the same order in the vcf as they are in the multicov bed file produced by bedtools!!*

```bash
#Generate a matrix of depth of coverage per sample per position:
./gen_bed_files.py reference.fa
bedtools multicov -bams path/to/bams/*.bam -bed reference_single_base.bed > multicov.bed
```
###STEP 2:
```bash
./vcf2fa.py --min_cov 18 --multicov_file multicov.bed --vcf_file var.vcf
#will generate a subfolder in the current directory of fasta files, each one a locus, containing all individuals found in the vcf/bed files
```