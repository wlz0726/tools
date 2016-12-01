#!/usr/bin/perl

use warnings;
use strict;

my $usage = "toVCF.pl file.calls";

my $file = $ARGV[0];
if (!$ARGV[0]) {
    print STDERR $usage,"\n";
    exit;
}

open(FILE,$file) or die "Can't open file ",$file,".\n";
print STDERR "Reading calls ...\n";
my ($pop_id) = split(/\./,$file);
print '##fileformat=VCFv4.0',"\n";
print '##fileDate='.`date '+%Y%m%d'`;
print '##reference=1000GenomesPhase1-GRCh37',"\n";
print '##source=CNVnator',"\n";
print '##INFO=<ID=END,Number=1,Type=Integer,Description="End position of the variant described in this record">',"\n";
print '##INFO=<ID=IMPRECISE,Number=0,Type=Flag,Description="Imprecise structural variation">',"\n";
print '##INFO=<ID=SVLEN,Number=1,Type=Integer,Description="Difference in length between REF and ALT alleles">',"\n";
print '##INFO=<ID=SVTYPE,Number=1,Type=String,Description="Type of structural variant">',"\n";
print '##INFO=<ID=natorRD,Number=1,Type=Float,Description="Normalized RD">',"\n";
print '##INFO=<ID=natorP1,Number=1,Type=Float,Description="p-val by t-test">',"\n";
print '##INFO=<ID=natorP2,Number=1,Type=Float,Description="p-val by Gaussian tail">',"\n";
print '##INFO=<ID=natorP3,Number=1,Type=Float,Description="p-val by t-test (middle)">',"\n";
print '##INFO=<ID=natorP4,Number=1,Type=Float,Description="p-val by Gaussian tail (middle)">',"\n";
print '##INFO=<ID=natorQ0,Number=1,Type=Float,Description="Fraction of reads with 0 mapping quality">',"\n";
print '##INFO=<ID=SAMPLES,Number=.,Type=String,Description="Sample genotyped to have the variant">',"\n";
print '##ALT=<ID=DEL,Description="Deletion">',"\n";
print '##ALT=<ID=DUP,Description="Duplication">',"\n";
print "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n";
my ($prev_chrom,$seq,$count) = ("","",0);
while (my $line = <FILE>) {
    my ($type,$coor,$len,$rd,$p1,$p2,$p3,$p4,$q0) = split(/\s+/,$line);
    my $pe = 0;
    my ($chrom,$start,$end) = split(/[\:\-]/,$coor);
    my $isDel = ($type eq "deletion");
    my $isDup = ($type eq "duplication");
    if ($isDup) {
    } elsif ($isDel) {
    } else {
	print STDERR "Skipping unrecognized event type '",$type,"'.\n";
	next;
    }
    $count++;
    my $id = "CNV_".$count;
    print $chrom,"\t",$start,"\t",$id,"\t.\t";
    if    ($isDel) { print "<DEL>"; }
    elsif ($isDup) { print "<DUP>"; }
    print "\t.\tPASS\t";
    my $INFO = "END=".$end;
    if    ($isDel) {
	$INFO .= ";SVTYPE=DEL";
	$INFO .= ";SVLEN=-".int($len);
    } elsif ($isDup) {
	$INFO .= ";SVTYPE=DUP";
	$INFO .= ";SVLEN=".int($len);
    }
    $INFO   .= ";IMPRECISE";
    $INFO   .= ";natorRD=".$rd;
    $INFO   .= ";natorP1=".$p1;
    $INFO   .= ";natorP2=".$p2;
    if (defined($p3)) { $INFO   .= ";natorP3=".$p3; }
    if (defined($p4)) { $INFO   .= ";natorP4=".$p4; }
    if (defined($q0)) { $INFO   .= ";natorQ0=".$q0; }
    print $INFO."\n";
}
close(FILE);

exit;
