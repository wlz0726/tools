#!/usr/bin/perl -w
my @file=<*.bam>;
foreach my $f(@file){
    chomp $f;
    print "perl Bam1MmeanQual.pl $f > $f.alnQ\n";
}
