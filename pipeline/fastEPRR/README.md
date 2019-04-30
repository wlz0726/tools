## 01.PopInfo.pl
  - mkdir for each population
  - file "sample_label.rename.ids" need two cols: id  population


## 02.splitVCF.pl
  - split vcf ; each one contains one population and one chr/scaffold
  - "snpdir" contain phased vcfs

## note:
  - you may need change the "LD_LIBRARY_PATH", "R_LIBS", "Rscript" for scripts:"02.fastEPRR.pl", "03.FastEPRR.step2and3.pl"
  - genome with **scaffolds** should remove the "#" of line 20 in "02.splitVCF.pl"