#!/usr/bin/perl

my $f=shift;
open(O,"> $f.r");
print O "
library(\"ggplot2\")
pdf(file=\"$f.pdf\",width=20,height=7)
#png(\"$f.png\")
a=read.table(\"$f\",header=F)
qplot(x=a\$V4, y=a\$V6, geom=\"line\")
dev.off()
";
close O;
`Rscript $f.r`;
`rm $f.r`;
