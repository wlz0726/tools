#!/usr/bin/perl -w
use strict;

my $cytoscape_list = shift;
my $gene_matrix = shift;

my %hash;
open CYTOSCAPE,"$cytoscape_list";
while(<CYTOSCAPE>){
	chomp;
	my @a = split;
	$hash{$a[0]} = 1;
	$hash{$a[1]} = 1;
}

open MATRIX,"$gene_matrix";
my $head = <MATRIX>;
print "$head";

while(<MATRIX>){
	my @a = split;
	if(exists $hash{$a[0]}){
		print "$_";
	}
}
