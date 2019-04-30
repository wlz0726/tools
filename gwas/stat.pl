#! /usr/bin/perl
use strict;
use warnings;

my $f=shift;
die "perl $0 <bfilePrefix>\n"unless $f;

print "
plink --noweb --bfile $f --freq --out data.freq;
plink --noweb --bfile $f --missing --out data.miss;
plink --noweb --bfile $f --hardy --out data.hwe;
";
