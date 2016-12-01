#! /usr/bin/perl
use strict;
use warnings;

my $list=shift;
die "$0 histList\n" unless $list;
open(OUT,"> $list.Rscript");
print OUT "pdf(file=\"$list.pdf\")\n";
print OUT "library(\"ggplot2\")\n";

print OUT "
a <- read.table(\"$list\",head=F)\n
ggplot(a,aes(a\$V1,a\$V2))+geom_bar(stat = \"identity\")+xlab(\"$list\")+ylab(\"count\")\n
";

print OUT "dev.off()\n";
close OUT;
`Rscript $list.Rscript`;
`rm $list.Rscript`;
