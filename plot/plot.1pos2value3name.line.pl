#!/usr/bin/perl

my $f=shift;
open(O,"> $f.line.r");
print O "
library(\"ggplot2\")
pdf(file=\"$f.line.pdf\",width=20,height=7)
a=read.table(\"$f\",header=F)
ggplot(a,aes(x=a\$V1,y=a\$V2))+geom_line(aes(colour=factor(a\$V3)))+scale_color_manual(values=c(\"#2166ac\",\"#b2182b\"))
dev.off()
#ggsave(filename=\"$f.pdf\",)
#$unlink(\"Rplots.pdf\", force=TRUE)
";
close O;
`Rscript $f.line.r`;
`rm $f.line.r`;
