#! /usr/bin/perl
use strict;
use warnings;

my $list=shift;
my $name=shift;
die "$0 List RowName\n" unless $name;
open(OUT,"> $list.$name.0.05.Rscript");
print OUT "pdf(file=\"$list.$name.0.05.pdf\")\n";
print OUT "library(\"ggplot2\")\n";

print OUT "
a <- read.table(\"$list\",header=T)\n
ggplot(a,aes(x=a\$$name))+geom_histogram(binwidth=10)+xlim(-1000,1000)+xlab(\"$list\")+ylab(\"frequence\")\n
";

print OUT "dev.off()\n";
close OUT;
`Rscript $list.$name.0.05.Rscript`;
