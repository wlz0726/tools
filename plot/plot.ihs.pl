#!/usr/bin/perl

my $f=shift;
open(O,"> $f.r");
print O "
library(\"ggplot2\")
pdf(file=\"$f.pdf\",width=20,height=7)
a=read.table(\"$f\",header=T)
qplot(x=a\$BIN_START, y=a\$iHS, geom=\"line\")
dev.off()
";
close O;
`Rscript $f.r`;
`rm $f.r`;
