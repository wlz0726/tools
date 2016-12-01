#!/usr/bin/perl -w
use strict;
use lib "/ifshk7/BC_PS/liaoqijun/soft/perlpackage/package";
use Text::NSP::Measures::2D::Fisher::right;

scalar @ARGV == 4 or die "\nUsage: perl $0 <significant gene list> <background gene list> <pathway list> <outfile>\n\n";

my $sigf = shift;
my $backf = shift;
my $pathf = shift;
my $outf = shift;

open IN, $sigf or die $!;
my %sig = ();
while (<IN>) {
	chomp;
	my @t = split;
	$sig{$t[0]} = 1;
}
close IN;
my @sigs = keys %sig;

open BK, $backf or die $!;
my %back = ();
while (<BK>) {
	chomp;
	my @t = split;
	$back{$t[1]} = $t[0];
}
close BK;

my @backs = keys %back;
my $n_back = scalar @backs;
my $n_sig  = scalar @sigs;


my $tmpf = "$outf.tmp";
open TMP, ">$tmpf" or die "Cannot open $tmpf\n";

open PA, $pathf or die $!;
while (<PA>) {
	chomp;
	my @t = split(/\t/, $_);
	my $path_id = $t[0];
	my $path_name = $t[1];
	my @path_genes = ();
	for my $i (2..$#t) {
		push @path_genes, $t[$i];
	}
	my $n_pathway_gene = scalar @path_genes;
	my ($n11, $overlap_str) = get_overlap(\@sigs, \@path_genes);
	my $n12 = $n_pathway_gene - $n11;
	my $n21 = $n_sig - $n11;
	my $n22 = $n_back - $n11 - $n12 - $n21;
	my $pvalue = 1;
	if ($n11 > 1) {
		#$pvalue = calculateStatistic(n11=>$n11, n1p=>$n_pathway_gene, np1=>$n_sig, npp=>$n_back);
		#$pvalue = sprintf("%.4E", $pvalue);
		print TMP join("\t", $path_id, $path_name, $pvalue, $n_pathway_gene, $n11, $n12, $n21, $n22, $overlap_str),"\n";
	}
}

close TMP;

system("/ifshk7/BC_PS/liaoqijun/soft/R-2.15.2/bin/Rscript /ifshk7/BC_PS/liaoqijun/public/kegg/enrich/fdr.R $tmpf $outf");

unlink $tmpf;

#print join("\t", "Pathway_ID", "Pathway_term", "Pvalue", "N_genes_in_pathway", "n11", 'n12', 'n21', 'n22', 'Genes_in_pathway'),"\n";

sub get_overlap {
	my ($a1, $a2) = @_;
	my %h = ();
	for my $g (@$a1) { $h{$g} += 1; }
	for my $g (@$a2) { $h{$g} += 2; }
	my $n_overlap = 0;
	my @overlap = ();
	for my $k (keys %h) {
		if ($h{$k} == 3) { $n_overlap += 1; push @overlap, $k; }
	}
	my $overlap_str = join(",", @overlap);
	$overlap_str ||= "NA";
	return ($n_overlap, $overlap_str);
}

