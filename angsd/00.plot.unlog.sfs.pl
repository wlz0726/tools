#! /usr/bin/perl
use strict;
use warnings;

my $file=shift;
die "$0 1.saf.sfs.unlog\n"unless $file;
open(OUT,"> $file.Rscript");
print OUT "
pdf(file=\"$file.pdf\")
norm <- function(x) x/sum(x)
sfs <- scan(\"$file\")
#the variability as percentile
pvar<- (1-sfs[1]-sfs[length(sfs)])*100
#the variable categories of the sfs
sfs<-norm(sfs[-c(1,length(sfs))]) 
barplot(sfs,legend=paste(\"Variability:= \",round(pvar,3),\"%\"),xlab=\"Chromosomes\",names=1:length(sfs),ylab=\"Proportions\",main=\"$file plot\",col=\'blue\')
dev.off()
";
close OUT;
`Rscript $file.Rscript`;
`rm $file.Rscript`;
