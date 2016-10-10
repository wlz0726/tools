#!/usr/bin/perl

my $f=shift;
open(O,"> $f.r");
print O "
library(\"ggplot2\")

a=read.table(\"$f\",header=F)
ggplot(a,aes(x=a\$V1,y=a\$V2))+geom_point(aes(colour=factor(a\$V3)),alpha=0.8)
ggsave(\"$f.pdf\")
unlink(\"Rplots.pdf\", force=TRUE)
";
close O;
`Rscript $f.r`;
`rm $f.r`;
