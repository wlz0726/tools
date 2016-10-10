#! /usr/bin/perl
use strict;
use warnings;

my $saf=shift;
my $chrs=shift;
die "$0 saf chrNumbers\n"unless $chrs;
open(OUT,"> $saf.sh");
print OUT "/home/share/software/ANGSD/angsd0.612/misc/realSFS $saf $chrs -P 30 > $saf.sfs; perl /home/share/user/user104/tools/angsd/000.log2unlog.MultpleSFS.pl $saf.sfs;perl /home/share/user/user104/tools/angsd/00.plot.unlog.sfs.pl $saf.sfs.unlog;\n";
close OUT;

`sh $saf.sh`;
