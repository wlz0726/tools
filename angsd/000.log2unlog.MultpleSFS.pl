#! /usr/bin/perl
use strict;
use warnings;

my $f=shift;
die "$0 *.saf.sfs \n  change log to unlog sfs\n "unless $f;

open(OUT,"> $f.r");
print OUT "
values <- read.table(\"$f\",header=F)
values = exp(values)
# Write
write.table(values,file=\"$f.unlog\",row.names=F,col.names=F)
";
close OUT;
`Rscript $f.r`;
`rm $f.r`;
