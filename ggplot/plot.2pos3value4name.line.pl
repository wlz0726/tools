#!/usr/bin/perl

my $f=shift;
open(O,"> $f.r");
print O "
library(\"ggplot2\")
pdf(file=\"$f.pdf\",width=20,height=7)
a=read.table(\"$f\",header=F)
qplot(x=a\$V2, y=a\$V3, colour=factor(a\$V4),alpha =0.02,geom=\"line\")

dev.off()
";
close O;
`Rscript $f.r`;
`rm $f.r`;
