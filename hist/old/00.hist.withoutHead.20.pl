#! /usr/bin/perl
use strict;
use warnings;

my $list=shift;
my $name=shift;
die "$0 histList Row(V1, V2 ,V3 ...)\n" unless $name;
open(OUT,"> $list.$name.Rscript");
print OUT "pdf(file=\"$list.$name.pdf\")\n";
print OUT "library(\"ggplot2\")\n";

print OUT "
a <- read.table(\"$list\",head=F)\n
ggplot(a,aes(x=a\$$name))+geom_histogram(binwidth=1)+xlim(0,40)+xlab(\"$list\")+ylab(\"frequence\")\n
";

print OUT "dev.off()\n";
close OUT;
`Rscript $list.$name.Rscript`;
